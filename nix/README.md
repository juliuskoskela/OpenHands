# Nix Configuration for OpenHands

This directory contains Nix configuration files for OpenHands development and deployment.

## Structure

```
nix/
├── README.md              # This file
├── modules/
│   └── openhands.nix     # NixOS module for system deployment
└── dev/
    ├── format.nix        # Code formatting utilities
    └── ci.nix           # CI/testing utilities
```

## Files

### `modules/openhands.nix`

A complete NixOS module that allows running OpenHands as a system service. Features:

- **Service Management**: Systemd service with proper user/group isolation
- **Configuration**: Declarative configuration via NixOS options
- **Security**: Sandboxed execution with minimal permissions
- **Docker Integration**: Optional Docker socket access for runtime
- **Environment Variables**: Support for API keys and tokens
- **Networking**: Configurable host/port binding

Example usage:
```nix
services.openhands = {
  enable = true;
  settings.port = 3000;
  environment.OPENAI_API_KEY = "your-key";
};
```

### `dev/format.nix`

Development utilities for code formatting:

- **Black**: Python code formatting
- **Ruff**: Fast Python linter and formatter
- **Prettier**: Frontend code formatting (when implemented)

Usage: `nix run .#fmt`

### `dev/ci.nix`

CI and testing utilities:

- **Test Runner**: Execute test suites
- **Linting**: Code quality checks
- **Type Checking**: MyPy integration
- **Pre-commit**: Git hook validation

Usage: `nix run .#ci`

## Development Workflow

1. **Enter Development Shell**:
   ```bash
   nix develop
   ```

2. **Install Dependencies**:
   ```bash
   poetry install
   cd frontend && npm install
   ```

3. **Format Code**:
   ```bash
   nix run .#fmt
   ```

4. **Run Tests**:
   ```bash
   nix run .#ci
   ```

5. **Build Application**:
   ```bash
   nix build .#openhands
   ```

## Deployment

### NixOS System

Add to your `flake.nix`:

```nix
{
  inputs.openhands.url = "github:All-Hands-AI/OpenHands";
  
  outputs = { self, nixpkgs, openhands }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        openhands.nixosModules.openhands
        {
          services.openhands.enable = true;
        }
      ];
    };
  };
}
```

### Standalone Package

```bash
# Install globally
nix profile install github:All-Hands-AI/OpenHands

# Run directly
nix run github:All-Hands-AI/OpenHands
```

## Configuration Options

The NixOS module supports these options:

- `services.openhands.enable`: Enable the service
- `services.openhands.package`: Package to use
- `services.openhands.user/group`: Service user/group
- `services.openhands.settings.*`: Application configuration
- `services.openhands.environment`: Environment variables
- `services.openhands.docker.*`: Docker integration settings

See `modules/openhands.nix` for complete option documentation.

## Future Enhancements

- **Poetry2nix Integration**: Full dependency management via Nix
- **Frontend Build**: Complete Node.js build pipeline
- **Container Images**: OCI container generation
- **Cross-compilation**: Multi-architecture builds
- **Development Tools**: Enhanced debugging and profiling
- **Testing Infrastructure**: Comprehensive test environments

## Contributing

When modifying Nix configurations:

1. Test changes with `nix flake check`
2. Validate NixOS module with a test VM
3. Update documentation for new options
4. Follow Nix community best practices
5. Ensure backward compatibility

## References

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Flake-parts Documentation](https://flake.parts/)
- [Poetry2nix Guide](https://github.com/nix-community/poetry2nix)