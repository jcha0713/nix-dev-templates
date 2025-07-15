# Nix dev templates

## Quick Start

Initialize the template:

```bash
nix flake init -t github:yourusername/dev-templates#base
```

Allow direnv:

```bash
direnv allow
```

## Third-party protection

Toggle protection on/off:

```bash
./toggle-protection.sh
```

or set it explicitly:

```bash
export DVT_THIRD_PARTY=true   # Enable protection
export DVT_THIRD_PARTY=false  # Disable protection
direnv reload
```
