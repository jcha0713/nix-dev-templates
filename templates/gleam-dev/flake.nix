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

        # Use shared template configurations and shell builder
        templateConfigs = nix-dev-templates.lib.getTemplateConfigs { inherit pkgs; };
        mkTemplateShell = nix-dev-templates.lib.mkTemplateShell { inherit pkgs; };

      in
      {
        devShells.default = mkTemplateShell "gleam-dev" templateConfigs.gleam-dev;

        # Formatter for `nix fmt`
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
