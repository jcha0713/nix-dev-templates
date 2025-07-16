{
  description = "Bun development environment";

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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Overlay to customize Bun version
        overlays = [
          (final: prev: {
            # Uncomment and modify to use a specific Bun version
            # bun = prev.bun.overrideAttrs (oldAttrs: rec {
            #   version = "1.0.25";
            #
            #   # Map flake-utils system to Bun release naming
            #   bunSystem = {
            #     "x86_64-linux" = "linux-x64";
            #     "aarch64-linux" = "linux-aarch64";
            #     "x86_64-darwin" = "darwin-x64";
            #     "aarch64-darwin" = "darwin-aarch64";
            #   }.${system};
            #
            #   src = prev.fetchurl {
            #     url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${bunSystem}.zip";
            #     hash = "sha256-your-hash-here";
            #   };
            # });

            # Alternative: Use latest Bun from GitHub releases
            # bun = prev.bun.overrideAttrs (oldAttrs: {
            #   src = prev.fetchFromGitHub {
            #     owner = "oven-sh";
            #     repo = "bun";
            #     rev = "bun-v1.0.25";  # or specific commit
            #     hash = "sha256-your-hash-here";
            #   };
            # });
          })
        ];

        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays;
        };

        # Use shared protection logic from root flake
        protection = nix-dev-templates.lib.protection { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
          ];

          shellHook = ''
            echo "🚀 Bun development environment loaded"
            ${protection.setupHook}
            echo "🍞 Bun $(bun --version) ready"
          '';

          NIX_SHELL_PRESERVE_PROMPT = "1";
        };
      }
    );
}
