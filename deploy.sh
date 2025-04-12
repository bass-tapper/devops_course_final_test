#!/bin/bash

# Rick and Morty API - Lean Deployment Script (cross-platform & CI friendly)

set -e
set -o pipefail

log_info() { echo "[INFO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_error() { echo "[ERROR] $1" >&2; }

check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        log_error "$1 is required but not installed. Aborting."
        exit 1
    }
}

IS_CI=${CI:-false}

cleanup() {
    local exit_code=$?
    log_info "Performing cleanup..."
    if [ "$IS_CI" != "true" ]; then
        pkill -f "kubectl port-forward" || true
        if [ -n "$DOCKER_ENV_SET" ]; then
            eval "$(minikube docker-env -u)"
        fi
    fi
    exit $exit_code
}
trap cleanup EXIT
trap 'log_error "Script interrupted."; exit 1' INT TERM

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
    --ci                    Force CI mode (simulate running in GitHub Actions)

Example:
    ./deploy.sh --namespace development --config dev.env
EOF
    exit 0
}

load_config() {
    local config_file="$1"
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from $config_file"
        source "$config_file"
    else
        log_warn "Config file not found: $config_file — using defaults."
    fi
}

check_prerequisites() {
    log_info "Checking system prerequisites..."
    local required_tools=("python3" "docker" "kubectl" "helm" "git")
    if [ "$IS_CI" != "true" ]; then
        required_tools+=("minikube")
    fi

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

# Default values
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
        --ci) IS_CI=true ;;
        *) log_error "Unknown option: $1"; show_usage ;;
    esac
    shift
done

check_prerequisites
load_config "$CONFIG_FILE"

log_info "Building Docker image..."
if [ "$IS_CI" != "true" ]; then
    eval "$(minikube docker-env)"
    DOCKER_ENV_SET=true
fi
docker build -t "${DOCKER_IMAGE_NAME:-rick-api}:${DOCKER_IMAGE_TAG:-latest}" ./sprint2/app

log_info "Deploying with Helm..."
helm upgrade --install "${HELM_RELEASE_NAME:-rick}" "${HELM_CHART_PATH:-./sprint4/helm/rick-api}" \
  --namespace "${NAMESPACE}" --create-namespace

log_info "Deployment complete."