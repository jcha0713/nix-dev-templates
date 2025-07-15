{
  description = "Base development environment with third-party protection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Import shared protection logic
        protection = import ../shared/protection.nix { inherit pkgs; };

      in
      {
        devShells.default = pkgs.mkShell {
          # Add new packages here!
          buildInputs = with pkgs; [ ];

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

        # Expose protection packages
        packages = protection.packages;

        # Expose protection apps
        apps = protection.apps;
      }
    );
}
