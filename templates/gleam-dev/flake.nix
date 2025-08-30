{
  description = "Gleam Core development environment";

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
        pkgs = nixpkgs.legacyPackages.${system};

        # Use shared protection logic from root flake
        protection = nix-dev-templates.lib.protection { inherit pkgs; };

      in
      {
        devShells.default = pkgs.mkShell {
          # Add new packages here!
          buildInputs = with pkgs; [
            bun
            erlang_28
            nodejs
            rebar3
            rustup
          ];

          shellHook = ''
            echo "🚀 Development environment loaded"

            # Use shared protection setup
            ${protection.setupHook}
          '';

          # Minimal environment setup
          NIX_SHELL_PRESERVE_PROMPT = "1";
        };

        # Formatter for `nix fmt`
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
