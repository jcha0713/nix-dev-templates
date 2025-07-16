{
  description = "Node.js development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-dev-templates.url = "github:jcha0713/nix-dev-templates";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nix-dev-templates,
    }:
    let
      overlay =
        final: prev:
        let
          # Read package.json if it exists
          packageJson =
            if builtins.pathExists ./package.json then
              builtins.fromJSON (builtins.readFile ./package.json)
            else
              { };

          # Extract pnpm version from packageManager field
          packageManagerSpec = packageJson.packageManager or "pnpm@latest";

          parsePnpmVersion =
            spec:
            let
              matchResult = builtins.match "pnpm@(.*)" spec;
            in
            if matchResult != null then builtins.head matchResult else null;

          pnpmVersion = parsePnpmVersion packageManagerSpec;

          # Automatic hash fetching for common pnpm versions
          # To add a new version hash, run: nix-prefetch-url https://registry.npmjs.org/pnpm/-/pnpm-VERSION.tgz
          pnpmHashes = {
            "8.15.4" = "sha256-hHIWjD4f0L/yh+aUsFP8y78gV5o/+VJrYzO+q432Wo0=";
            "9.0.0" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual
            "9.1.0" = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Replace with actual
            # Add more versions as needed
          };

          getPnpmSrc =
            version:
            let
              url = "https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz";
              knownHash = pnpmHashes.${version} or null;
            in
            if knownHash != null then
              prev.fetchurl {
                inherit url;
                hash = knownHash;
              }
            else
              # For unknown versions, the build will fail with the correct hash
              # Copy the suggested hash and add it to pnpmHashes above
              prev.fetchurl {
                inherit url;
                hash = prev.lib.fakeHash;
              };

        in
        {
          nodejs = prev.nodejs_20; # Use explicit Node.js 20 LTS

          yarn-berry = prev.yarn-berry.override {
            nodejs = final.nodejs;
          };

          pnpm =
            if pnpmVersion != null && pnpmVersion != "latest" then
              prev.pnpm.overrideAttrs (oldAttrs: {
                version = pnpmVersion;
                src = getPnpmSrc pnpmVersion;
              })
            else
              prev.pnpm; # Use default pnpm version
        };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

        # Use shared protection logic from root flake
        protection = nix-dev-templates.lib.protection { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            pnpm
            yarn-berry
            node2nix
            jq # For parsing package.json in shellHook

            # Helper script to get pnpm hash for new versions
            (writeShellScriptBin "get-pnpm-hash" ''
              if [ -z "$1" ]; then
                echo "Usage: get-pnpm-hash <version>"
                echo "Example: get-pnpm-hash 9.1.0"
                exit 1
              fi
              echo "Fetching hash for pnpm $1..."
              nix-prefetch-url "https://registry.npmjs.org/pnpm/-/pnpm-$1.tgz"
            '')
          ];

          shellHook = ''
            echo "🚀 Node.js development environment loaded"
            ${protection.setupHook}
            echo "📦 Node.js $(node --version)"
            echo "📦 pnpm $(pnpm --version)"
            echo "📦 yarn $(yarn --version)"

            ${
              if (builtins.pathExists ./package.json) then
                ''
                  echo "📄 Detected package.json"
                  if [[ -f package.json ]] && command -v jq >/dev/null 2>&1; then
                    packageManager=$(jq -r '.packageManager // "not specified"' package.json)
                    echo "📋 Package manager: $packageManager"
                  fi
                ''
              else
                ''
                  echo "📄 No package.json found - run 'npm init' or 'pnpm init' to create one"
                ''
            }

            echo ""
            echo "💡 To add a new pnpm version hash:"
            echo "   1. Run: get-pnpm-hash <version>"  
            echo "   2. Add the hash to pnpmHashes in flake.nix"
          '';

          NIX_SHELL_PRESERVE_PROMPT = "1";
        };

        # Expose the overlay for reuse
        overlays.default = overlay;

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
