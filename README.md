# Nix dev templates

## Quick Start

Initialize the template:

```bash
nix flake init -t github:jcha0713/nix-dev-templates#base
```

Allow direnv:

```bash
direnv allow
```

## Third-party protection

```bash
export DVT_THIRD_PARTY=true   # Enable protection
export DVT_THIRD_PARTY=false  # Disable protection
direnv reload
```
