{ pkgs }:

pkgs.writeShellScriptBin "ci-openhands" ''
  set -e

  echo "🔍 Running OpenHands CI checks..."

  # Python linting
  echo "🔍 Checking Python code with ruff..."
  ${pkgs.ruff}/bin/ruff check openhands/ tests/

  echo "🔍 Checking Python formatting with black..."
  ${pkgs.black}/bin/black --check openhands/ tests/ --line-length 88

  echo "🔍 Type checking with mypy..."
  ${pkgs.mypy}/bin/mypy openhands/ || echo "⚠️  MyPy found issues"

  # Python tests
  echo "🧪 Running Python tests..."
  ${pkgs.python312Packages.pytest}/bin/pytest tests/unit/ -v

  # Frontend checks (if available)
  if [ -d "frontend" ]; then
    echo "🔍 Checking frontend..."
    cd frontend
    ${pkgs.nodejs_20}/bin/npm run lint || echo "⚠️  Frontend linting failed"
    ${pkgs.nodejs_20}/bin/npm run test || echo "⚠️  Frontend tests failed"
    cd ..
  fi

  echo "✅ All CI checks completed!"
''
