{ pkgs }:

pkgs.writeShellScriptBin "format-openhands" ''
  set -e

  echo "🎨 Formatting OpenHands codebase..."

  # Python formatting
  echo "📝 Formatting Python code with black..."
  ${pkgs.black}/bin/black openhands/ tests/ --line-length 88

  echo "📝 Formatting Python code with ruff..."
  ${pkgs.ruff}/bin/ruff format openhands/ tests/

  # Frontend formatting (if available)
  if [ -d "frontend" ]; then
    echo "📝 Formatting frontend code..."
    cd frontend
    ${pkgs.nodejs_20}/bin/npm run lint:fix || echo "⚠️  Frontend linting failed or not configured"
    cd ..
  fi

  echo "✅ Formatting complete!"
''
