#!/usr/bin/env bash
set -euo pipefail

# This script bootstraps micromamba (if needed), creates/updates the env from
# conda.yaml, and activates the environment.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Allow overriding via args; defaults are sensible for this repo
ENV_NAME="${1:-dinov3}"
ENV_FILE="${2:-$REPO_ROOT/conda.yaml}"

echo "[setup] Repo: $REPO_ROOT"
echo "[setup] Env name: $ENV_NAME"
echo "[setup] Env file: $ENV_FILE"

if [ ! -f "$ENV_FILE" ]; then
  echo "[setup] ERROR: Environment file not found at $ENV_FILE" >&2
  exit 1
fi

# Ensure micromamba is available
export PATH="$HOME/.local/bin:$PATH"
if ! command -v micromamba >/dev/null 2>&1; then
  echo "[setup] Installing micromamba to $HOME/.local/bin ..."
  mkdir -p "$HOME/.local/bin"
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
    | tar -xj -O bin/micromamba > "$HOME/.local/bin/micromamba"
  chmod +x "$HOME/.local/bin/micromamba"
fi

# Configure micromamba root prefix and shell integration
export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/micromamba}"
export MAMBA_EXE="$(command -v micromamba)"
eval "$("$MAMBA_EXE" shell hook -s bash)"

# Create or update the environment
if micromamba env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  echo "[setup] Updating existing environment: $ENV_NAME"
  micromamba env update -n "$ENV_NAME" -f "$ENV_FILE" -y
else
  echo "[setup] Creating environment: $ENV_NAME"
  micromamba env create -n "$ENV_NAME" -f "$ENV_FILE" -y
fi

echo "[setup] Activating environment: $ENV_NAME"
micromamba activate "$ENV_NAME"

python -V
echo "[setup] Done. To activate later in a new shell, run:"
echo "  export PATH=\"$HOME/.local/bin:\$PATH\""
echo "  export MAMBA_ROOT_PREFIX=\"$HOME/micromamba\""
echo "  eval \"\$(micromamba shell hook -s bash)\""
echo "  micromamba activate $ENV_NAME"


