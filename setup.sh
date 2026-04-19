#!/bin/bash

# ============================================================
#  Apache Airflow 3.1.0 — Local Project-Specific Setup
#  - Fixed for paths containing spaces
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# CRITICAL: All paths wrapped in quotes to handle the "data engineer" space
PROJECT_ROOT="$(pwd)"
VENV_DIR="$PROJECT_ROOT/.venv"
export AIRFLOW_HOME="$PROJECT_ROOT/airflow_home"
AIRFLOW_PORT="8080"

print_step()    { echo -e "\n${BLUE}━━━ STEP $1: $2 ━━━${NC}"; }
print_info()    { echo -e "${YELLOW}  ➜  $1${NC}"; }
print_success() { echo -e "${GREEN}  ✔  $1${NC}"; }

clear
echo -e "${GREEN}Setting up Airflow in: $PROJECT_ROOT${NC}"

# 1. Kill old processes
print_step "1" "Cleaning old processes"
pkill -9 -f "airflow" 2>/dev/null || true

# 2. Check Python
print_step "2" "Checking Python"
PYTHON_BIN="python3"
PY_VER=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
print_success "Using Python $PY_VER"

# 3. Create VENV in the current folder
print_step "3" "Creating virtual environment"
if [ ! -d "$VENV_DIR" ]; then
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# Define paths to binaries inside quotes
PIP="$VENV_DIR/bin/pip"
AIRFLOW_BIN="$VENV_DIR/bin/airflow"

# 4. Install Airflow
print_step "4" "Installing Airflow 3.1.0"
"$PIP" install --upgrade pip --quiet

# Dynamically fetch constraints for Airflow 3.1.0
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-3.1.0/constraints-${PY_VER}.txt"
print_info "Using constraints: $CONSTRAINT_URL"

"$PIP" install "apache-airflow==3.1.0" --constraint "$CONSTRAINT_URL"

# 5. Configure Workspace
print_step "5" "Configuring Workspace"
mkdir -p "$AIRFLOW_HOME/dags" "$AIRFLOW_HOME/logs"

# Use 127.0.0.1 for local PC security
export AIRFLOW__API__HOST="127.0.0.1"
export AIRFLOW__API__BASE_URL="http://localhost:${AIRFLOW_PORT}"

# 6. Create a local helper script
cat > "activate_project.sh" << EOF
export AIRFLOW_HOME="$AIRFLOW_HOME"
source "$VENV_DIR/bin/activate"
echo "Airflow environment activated!"
echo "AIRFLOW_HOME is set to: \$AIRFLOW_HOME"
EOF
chmod +x "activate_project.sh"

print_success "Setup Complete!"
echo -e "${YELLOW}To activate this environment later, run: source activate_project.sh${NC}"
echo ""

# 7. Launch
print_step "6" "Launching Standalone"
# Using "exec" with the quoted binary path
exec "$AIRFLOW_BIN" standalone