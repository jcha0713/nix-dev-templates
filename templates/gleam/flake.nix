{
  description = "Gleam development environment";

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
          buildInputs = with pkgs; [
            gleam
            erlang
            rebar3
            # Optional: JavaScript runtime for JS target
            nodejs
            # Optional: Alternative JS runtime
            # deno
          ];

          shellHook = ''
            echo "✨ Gleam development environment loaded"
            ${protection.setupHook}
            echo "📦 Gleam $(gleam --version)"
            echo "📦 Erlang $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)"
            echo "📦 Node.js $(node --version)"
          '';

          NIX_SHELL_PRESERVE_PROMPT = "1";
        };

        formatter = pkgs.nixpkgs-fmt;

        packages = {
          default = pkgs.gleam;
        };
      }
    );
}
