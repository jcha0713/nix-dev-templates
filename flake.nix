{
  description = "My Collection of Nix Flake Templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Use shared template configurations
        templateConfigs = self.lib.getTemplateConfigs { inherit pkgs; };
        mkTemplateShell = self.lib.mkTemplateShell { inherit pkgs; };
      in
      {
        devShells = {
          default = mkTemplateShell "base" templateConfigs.base;
          base = mkTemplateShell "base" templateConfigs.base;
          bun = mkTemplateShell "bun" templateConfigs.bun;
          node = mkTemplateShell "node" templateConfigs.node;
          gleam = mkTemplateShell "gleam" templateConfigs.gleam;
          gleam-dev = mkTemplateShell "gleam-dev" templateConfigs.gleam-dev;
        };
      }
    )
    // {
      lib = {
        # Export template configuration function
        getTemplateConfigs = { pkgs }: {
          base = {
            buildInputs = with pkgs; [ ];
            shellMessage = "🚀 Base development environment loaded";
            versionInfo = "";
          };

          bun = {
            buildInputs = with pkgs; [ bun ];
            shellMessage = "🚀 Bun development environment loaded";
            versionInfo = "echo \"🍞 Bun $(bun --version) ready\"";
          };

          node = {
            buildInputs = with pkgs; [ 
              nodejs_20 
              pnpm 
              yarn-berry 
              node2nix 
              jq
              # Helper script to get pnpm hash for new versions
              (pkgs.writeShellScriptBin "get-pnpm-hash" ''
                if [ -z "$1" ]; then
                  echo "Usage: get-pnpm-hash <version>"
                  echo "Example: get-pnpm-hash 9.1.0"
                  exit 1
                fi
                echo "Fetching hash for pnpm $1..."
                nix-prefetch-url "https://registry.npmjs.org/pnpm/-/pnpm-$1.tgz"
              '')
            ];
            shellMessage = "🚀 Node.js development environment loaded";
            versionInfo = ''
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
          };

          gleam = {
            buildInputs = with pkgs; [ gleam erlang rebar3 nodejs ];
            shellMessage = "✨ Gleam development environment loaded";
            versionInfo = ''
              echo "📦 Gleam $(gleam --version)"
              echo "📦 Node.js $(node --version)"
            '';
          };

          gleam-dev = {
            buildInputs = with pkgs; [ pkgs.beam28Packages.elixir bun erlang_28 nodejs rebar3 rustup ];
            shellMessage = "🚀 Gleam Core development environment loaded";
            versionInfo = "";
          };
        };

        # Export helper function for creating shells with shared protection logic
        mkTemplateShell = { pkgs }: name: config: pkgs.mkShell {
          buildInputs = config.buildInputs;

          shellHook = ''
            echo "${config.shellMessage}"
            ${config.versionInfo}

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
