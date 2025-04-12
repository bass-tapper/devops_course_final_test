#!/bin/bash

# Rick and Morty API - Deployment Script
# Supports Linux, macOS, WSL (for Windows)

set -e
set -o pipefail

# Color-coded logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        log_error "$1 is required but not installed. Aborting."
        exit 1
    }
}

# Cleanup logic for Ctrl+C and script exit
cleanup() {
    local exit_code=$?
    log_info "Performing cleanup..."
    pkill -f "kubectl port-forward" || true
    if [ -n "$DOCKER_ENV_SET" ]; then
        eval "$(minikube docker-env -u)"
    fi
    exit $exit_code
}
trap cleanup EXIT
trap 'log_error "Script interrupted."; exit 1' INT TERM

# Usage instructions
show_usage() {
    cat << EOF
Usage: ./deploy.sh [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --debug             Enable debug mode
    -n, --namespace NAME    Deploy to specific namespace (default: default)
    -c, --config FILE       Use custom config file
    -f, --force             Force deployment even if resources exist
    --skip-tests            Skip running tests
    --dry-run               Perform a dry run without making changes

Example:
    ./deploy.sh --namespace development --config dev.env

Requirements:
    - Docker Desktop running
    - Minikube installed
    - Helm 3.x installed
    - kubectl configured
    - At least 5GB free disk space
EOF
    exit 0
}

# Load configuration from env file
load_config() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from $config_file"
        source "$config_file"
    else
        log_warn "Config file not found: $config_file — using defaults."
    fi
}

# Prerequisite checks
check_prerequisites() {
    log_info "Checking system prerequisites..."
    local required_tools=("python3" "docker" "kubectl" "minikube" "helm" "git")
    local required_space=5
    local available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "$available_space" -lt "$required_space" ]; then
        log_error "Insufficient disk space. Required: ${required_space}GB, Available: ${available_space}GB"
        exit 1
    fi

    for tool in "${required_tools[@]}"; do
        check_command "$tool"
    done
}

# Minimal argument parser
CONFIG_FILE="config.env"
NAMESPACE="default"
DEBUG=0
DRY_RUN=0

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help) show_usage ;;
        -d|--debug) DEBUG=1 ;;
        -n|--namespace) NAMESPACE="$2"; shift ;;
        -c|--config) CONFIG_FILE="$2"; shift ;;
        --dry-run) DRY_RUN=1 ;;
        *) log_error "Unknown option: $1"; show_usage ;;
    esac
    shift
done

# Main Script Logic
check_prerequisites
load_config "$CONFIG_FILE"

log_info "Building Docker image..."
eval "$(minikube docker-env)"
DOCKER_ENV_SET=true
docker build -t "${DOCKER_IMAGE_NAME:-rick-api}:${DOCKER_IMAGE_TAG:-latest}" ./sprint2/app

log_info "Deploying with Helm..."
helm upgrade --install "${HELM_RELEASE_NAME:-rick}" "${HELM_CHART_PATH:-./sprint4/helm/rick-api}" \
  --namespace "${NAMESPACE}" --create-namespace

log_info "Deployment complete ✅"