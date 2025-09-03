# Nix dev templates

## Usage Methods

### Method 1: Remote flake (recommended)

Add to `.envrc`:

```bash
use flake github:jcha0713/nix-dev-templates#<template>
```

Example:

```bash
echo "use flake github:jcha0713/nix-dev-templates#node" > .envrc
direnv allow
```

### Method 2: Local flake

Initialize the template:

```bash
nix flake init -t github:jcha0713/nix-dev-templates#base
direnv allow
```

## Third-party protection

```bash
export DVT_THIRD_PARTY=true   # Enable protection
export DVT_THIRD_PARTY=false  # Disable protection
direnv reload
```
