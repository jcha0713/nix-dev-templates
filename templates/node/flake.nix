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
      # Define overlay outside of eachDefaultSystem so it can be exposed globally
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

        # Use shared template configurations and shell builder
        templateConfigs = nix-dev-templates.lib.getTemplateConfigs { inherit pkgs; };
        mkTemplateShell = nix-dev-templates.lib.mkTemplateShell { inherit pkgs; };
      in
      {
        devShells.default = mkTemplateShell "node" templateConfigs.node;

        formatter = pkgs.nixpkgs-fmt;
      }
    ) // {
      # Expose the overlay for reuse
      overlays.default = overlay;
    };
}
