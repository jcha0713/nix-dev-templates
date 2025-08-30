{
  description = "My Collection of Nix Flake Templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells = {
          gleam-dev = pkgs.mkShell {
            buildInputs = with pkgs; [
              bun
              erlang_28
              nodejs
              rebar3
              rustup
            ];

            shellHook = ''
              echo "🚀 Development environment loaded"

              # Early return if no .git directory (must be own repo)
              if [ ! -d .git ]; then
                echo ""
                echo "🏠 Own repository mode (no .git directory)"
                echo "   • Flake files can be committed normally"
                return
              fi

              # Set up protection if in third-party mode
              if [ "$DVT_THIRD_PARTY" = "true" ]; then
                export NIX_THIRD_PARTY_MODE=true
                echo ""
                echo "🛡️  Third-party protection is ACTIVE"
                echo "   • Flake files are protected from commits"
                echo "   • To disable: unset DVT_THIRD_PARTY"
              else
                echo ""
                echo "🏠 Own repository mode"
                echo "   • Flake files can be committed normally"
                echo "   • To enable protection: export DVT_THIRD_PARTY=true"
              fi
            '';

            NIX_SHELL_PRESERVE_PROMPT = "1";
          };
        };
      }) // {
      lib = {
        protection =
          { pkgs }:
          let
            thirdPartyProtection = pkgs.writeShellScript "setup-third-party-protection" ''
                  # Third-party repository protection setup
                  echo "🛡️  Setting up third-party protection..."

                  # Create pre-commit hook
                  if [ -d .git ] && [ ! -f .git/hooks/pre-commit ]; then
                    mkdir -p .git/hooks
                    cat > .git/hooks/pre-commit << 'HOOK_EOF'
              #!/usr/bin/env bash
              if [ "$DVT_THIRD_PARTY" = "true" ] || [ "$NIX_THIRD_PARTY_MODE" = "true" ]; then
                  echo "🔍 Checking for flake files in commit..."

                  flake_files=$(git diff --cached --name-only | grep -E "(flake\.(nix|lock))$" || true)
                  if [ -n "$flake_files" ]; then
                      echo "❌ Error: Cannot commit flake files in third-party mode"
                      echo ""
                      echo "Files that would be committed:"
                      echo "$flake_files" | sed 's/^/  - /'
                      echo ""
                      echo "To disable protection, run:"
                      echo "  unset DVT_THIRD_PARTY"
                      echo "  unset NIX_THIRD_PARTY_MODE"
                      echo "  git commit"
                      exit 1
                  fi
                  echo "✅ No flake files in commit"
              fi
              HOOK_EOF
                    chmod +x .git/hooks/pre-commit
                    echo "✅ Pre-commit hook installed"
                  fi

                  # Hide flake files from git status
                  if [ -d .git ]; then
                    git update-index --skip-worktree flake.nix flake.lock 2>/dev/null || true
                    echo "✅ Flake files hidden from git status"
                  fi
            '';

          in
          {
            # Export individual components
            inherit thirdPartyProtection;

            # Complete setup hook that can be used in shellHook
            setupHook = ''
              # Early return if no .git directory (must be own repo)
              if [ ! -d .git ]; then
                echo ""
                echo "🏠 Own repository mode (no .git directory)"
                echo "   • Flake files can be committed normally"
                return
              fi

              # Set up protection if in third-party mode
              if [ "$DVT_THIRD_PARTY" = "true" ]; then
                export NIX_THIRD_PARTY_MODE=true
                ${thirdPartyProtection}
                echo ""
                echo "🛡️  Third-party protection is ACTIVE"
                echo "   • Flake files are protected from commits"
                echo "   • To disable: unset DVT_THIRD_PARTY"
              else
                echo ""
                echo "🏠 Own repository mode"
                echo "   • Flake files can be committed normally"
                echo "   • To enable protection: export DVT_THIRD_PARTY=true"
              fi
            '';

            # Packages that can be exposed
            packages = {
              protection-setup = thirdPartyProtection;
            };

            # Apps that can be run with `nix run`
            apps = {
              setup-protection = {
                type = "app";
                program = "${thirdPartyProtection}";
              };
            };
          };
      };

      templates = {
        base = {
          path = ./templates/base;
          description = "A base template.";
        };
        bun = {
          path = ./templates/bun;
          description = "Bun template.";
        };
        node = {
          path = ./templates/node;
          description = "Node template.";
        };
        gleam = {
          path = ./templates/gleam;
          description = "Gleam template";
        };
        gleam-dev = {
          path = ./templates/gleam-dev;
          description = "Gleam Core development environment";
        };

        defaultTemplate = self.templates.base;
      };
    };
}
