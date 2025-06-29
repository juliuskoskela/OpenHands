# Poetry2nix Integration Roadmap

You're absolutely right! The current implementation is incomplete and doesn't leverage the full power of Nix. Here's the roadmap to proper poetry2nix integration.

## Current Status

**What Works:**
- ✅ Development shell with Python 3.12, Node.js, Poetry, and dev tools
- ✅ NixOS module for system deployment
- ✅ Basic Nix flake structure

**What's Missing:**
- ❌ Full poetry2nix integration for dependency management
- ❌ Proper package builds without requiring `poetry install`
- ❌ Reproducible Python environment from poetry.lock

## The Problem

Currently, users still need to run `poetry install` because:

1. **Dependency Complexity**: OpenHands has many complex Python dependencies
2. **Package Conflicts**: Some packages in poetry.lock conflict with nixpkgs versions
3. **Build Environment Issues**: Current build sandbox has permission problems

## Poetry2nix Integration Plan

### Phase 1: Basic Integration (In Progress)
```nix
# Added poetry2nix input
poetry2nix = {
  url = "github:nix-community/poetry2nix";
  inputs.nixpkgs.follows = "nixpkgs";
};

# Create Python environment from poetry.lock
pythonEnv = poetry2nix.mkPoetryEnv {
  projectDir = ./.;
  preferWheels = true;
  overrides = poetry2nix.overrides.withDefaults (final: prev: {
    # Handle problematic packages
  });
};
```

### Phase 2: Dependency Resolution
**Issues to resolve:**
- `types-typed-ast` - removed from nixpkgs
- `fastapi-cli` - missing optional-dependencies
- Complex ML/AI packages that need system libraries

**Solutions:**
```nix
overrides = poetry2nix.overrides.withDefaults (final: prev: {
  # Skip obsolete packages
  types-typed-ast = null;
  
  # Add system dependencies
  numpy = prev.numpy.overridePythonAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.gfortran ];
  });
  
  # Handle Docker integration
  docker = prev.docker.overridePythonAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.docker ];
  });
});
```

### Phase 3: Package Building
```nix
openhandsApp = poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  preferWheels = true;
  overrides = /* same as above */;
};

# Then users can run:
# nix run .#openhands  # No poetry install needed!
```

### Phase 4: Development Environment
```nix
devShells.default = pkgs.mkShell {
  buildInputs = [
    pythonEnv  # All dependencies from poetry.lock
    nodejs_20
    git
    docker
  ];
  
  shellHook = ''
    echo "All Python dependencies available via Nix!"
    echo "Run: python -m openhands.server"
  '';
};
```

## Current Workaround

Until poetry2nix is fully integrated:

```bash
# Use the hybrid approach
nix develop
poetry install
poetry run python -m openhands.server
```

This gives you:
- ✅ Reproducible system dependencies (via Nix)
- ✅ Exact Python dependencies (via Poetry)
- ✅ Consistent development environment

## Next Steps

1. **Resolve dependency conflicts** - Create comprehensive overrides
2. **Fix build environment** - Investigate permission issues
3. **Test incrementally** - Add packages one by one
4. **Document overrides** - For future maintainers

## Timeline

- **Week 1**: Resolve major dependency conflicts
- **Week 2**: Get basic poetry2nix environment working
- **Week 3**: Full application package building
- **Week 4**: Documentation and testing

## Benefits Once Complete

- 🚀 **One-command setup**: `nix develop` gives you everything
- 🔒 **Reproducible builds**: Same environment everywhere
- 📦 **No poetry install**: Dependencies managed by Nix
- 🏗️ **Binary caching**: Faster builds with Nix cache
- 🐳 **No Docker needed**: Pure Nix deployment

## References

- [poetry2nix documentation](https://github.com/nix-community/poetry2nix)
- [OpenHands dependencies](./pyproject.toml)
- [Current flake implementation](./flake.nix)

---

**Status**: In active development  
**ETA**: 2-4 weeks for full integration  
**Current**: Hybrid Nix + Poetry approach working