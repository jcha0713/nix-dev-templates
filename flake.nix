{
  description = "My Collection of Nix Flake Templates";

  outputs =
    { self, nixpkgs, ... }:
    {
      lib = {
        protection = { pkgs }:
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
                git update-index --assume-unchanged flake.nix flake.lock 2>/dev/null || true
                echo "✅ Flake files hidden from git status"
              fi
              
              # Create convenience script to toggle protection
              cat > toggle-protection.sh << 'TOGGLE_EOF'
          #!/usr/bin/env bash
          if [ "$DVT_THIRD_PARTY" = "true" ]; then
              echo "🔓 Disabling third-party protection..."
              unset DVT_THIRD_PARTY
              unset NIX_THIRD_PARTY_MODE
              git update-index --no-assume-unchanged flake.nix flake.lock 2>/dev/null || true
              echo "export DVT_THIRD_PARTY=false" > .envrc.local
              echo "✅ Protection disabled - you can now commit flake files"
          else
              echo "🔒 Enabling third-party protection..."
              export DVT_THIRD_PARTY=true
              export NIX_THIRD_PARTY_MODE=true
              git update-index --assume-unchanged flake.nix flake.lock 2>/dev/null || true
              echo "export DVT_THIRD_PARTY=true" > .envrc.local
              echo "export NIX_THIRD_PARTY_MODE=true" >> .envrc.local
              echo "✅ Protection enabled - flake files are protected from commits"
          fi
          TOGGLE_EOF
              chmod +x toggle-protection.sh
              echo "✅ Toggle script created: ./toggle-protection.sh"
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

              # Load local environment if it exists
              if [ -f .envrc.local ]; then
                source .envrc.local
              fi

              # Set up protection if in third-party mode
              if [ "$DVT_THIRD_PARTY" = "true" ]; then
                export NIX_THIRD_PARTY_MODE=true
                ${thirdPartyProtection}
                echo ""
                echo "🛡️  Third-party protection is ACTIVE"
                echo "   • Flake files are protected from commits"
                echo "   • Use ./toggle-protection.sh to disable"
              else
                echo ""
                echo "🏠 Own repository mode"
                echo "   • Flake files can be committed normally"
                echo "   • Use ./toggle-protection.sh to enable protection"
              fi

              echo ""
              echo "💡 Use ./toggle-protection.sh to toggle protection mode"

              # Create toggle script if it doesn't exist
              if [ ! -f toggle-protection.sh ]; then
                ${thirdPartyProtection}
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

        defaultTemplate = self.templates.base;
      };
    };
}
