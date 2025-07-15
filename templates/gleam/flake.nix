{
  description = "Gleam development environment";

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
        protection = import ../shared/protection.nix { inherit pkgs; };
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
