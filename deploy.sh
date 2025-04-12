#!/bin/bash

# Rick and Morty API - Universal Deployment Script (CI-aware, self-starting)

set -e
set -o pipefail

log_info() { echo "[INFO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_error() { echo "[ERROR] $1" >&2; }

IS_CI=${CI:-false}
OS_TYPE="unknown"

detect_os() {
  case "$OSTYPE" in
    linux*) OS_TYPE="linux" ;;
    darwin*) OS_TYPE="macos" ;;
    msys*|cygwin*|win32*) OS_TYPE="windows" ;; # Basic fallback
  esac
}

check_command() {
  command -v "$1" >/dev/null 2>&1
}

install_tool() {
  local tool=$1
  if [ "$OS_TYPE" == "macos" ]; then
    if check_command brew; then
      log_info "Installing $tool with Homebrew..."
      brew install $tool
    else
      log_error "Homebrew not found. Please install $tool manually."
      exit 1
    fi
  elif [ "$OS_TYPE" == "linux" ]; then
    if check_command apt; then
      log_info "Installing $tool with apt..."
      sudo apt-get update && sudo apt-get install -y $tool
    elif check_command yum; then
      log_info "Installing $tool with yum..."
      sudo yum install -y $tool
    else
      log_error "No supported package manager found to install $tool."
      exit 1
    fi
  else
    log_error "Cannot install $tool automatically on $OS_TYPE."
    exit 1
  fi
}

ensure_tools_installed() {
  local tools=("python3" "docker" "kubectl" "helm" "git")
  if [ "$IS_CI" != "true" ]; then
    tools+=("minikube")
  fi

  for tool in "${tools[@]}"; do
    if ! check_command "$tool"; then
      log_warn "$tool is missing."
      install_tool "$tool"
    else
      log_info "$tool is installed."
    fi
  done
}

start_docker_if_needed() {
  if ! docker info >/dev/null 2>&1; then
    log_warn "Docker not running. Attempting to start..."
    if [ "$OS_TYPE" == "macos" ]; then
      open -a Docker
      log_info "Waiting for Docker to become ready..."
      until docker info >/dev/null 2>&1; do sleep 1; done
    elif [ "$OS_TYPE" == "linux" ]; then
      sudo systemctl start docker
    else
      log_error "Cannot auto-start Docker on $OS_TYPE."
      exit 1
    fi
  fi
}

check_system_resources() {
  if [ "$OS_TYPE" == "macos" ]; then
    available_space=$(df -g . | awk 'NR==2 {print $4}')
    total_mem=$(sysctl -n hw.memsize)
  else
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2 * 1024}')
  fi

  if [ "$available_space" -lt 5 ]; then
    log_error "Insufficient disk space. Needed: 5GB, Available: ${available_space}GB"
    exit 1
  fi

  if [ "$total_mem" -lt $((4*1024*1024*1024)) ]; then
    log_error "Insufficient RAM (< 4GB)."
    exit 1
  fi
}

start_minikube_if_needed() {
  if [ "$IS_CI" != "true" ]; then
    if ! minikube status | grep -q 'Running'; then
      log_info "Starting Minikube..."
      minikube start
    fi

    log_info "Enabling Ingress in Minikube..."
    minikube addons enable ingress
  fi
}

verify_k8s_context() {
  if ! kubectl config current-context &>/dev/null; then
    log_error "No Kubernetes context set. Is Minikube running?"
    exit 1
  fi
}

ensure_helm_repo() {
  if ! helm repo list | grep -q stable; then
    log_info "Adding Helm stable repo..."
    helm repo add stable https://charts.helm.sh/stable
    helm repo update
  fi
}

# CONFIG SETUP
CONFIG_FILE="config.env"
NAMESPACE="default"
DEBUG=0
DRY_RUN=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help) echo "Usage: ./deploy.sh [--ci] [--config FILE]"; exit 0 ;;
    -n|--namespace) NAMESPACE="$2"; shift ;;
    -c|--config) CONFIG_FILE="$2"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --debug) DEBUG=1 ;;
    --ci) IS_CI=true ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# STARTUP
detect_os
log_info "Detected OS: $OS_TYPE"
ensure_tools_installed
start_docker_if_needed
check_system_resources
start_minikube_if_needed
verify_k8s_context
ensure_helm_repo

if [ -f "$CONFIG_FILE" ]; then
  log_info "Loading config from $CONFIG_FILE"
  source "$CONFIG_FILE"
else
  log_warn "No config file found. Using defaults."
fi

log_info "Building Docker image..."
if [ "$IS_CI" != "true" ]; then
  eval "$(minikube docker-env)"
fi
docker build -t "${DOCKER_IMAGE_NAME:-rick-api}:${DOCKER_IMAGE_TAG:-latest}" ./sprint2/app

log_info "Deploying with Helm..."
helm upgrade --install "${HELM_RELEASE_NAME:-rick}" "${HELM_CHART_PATH:-./sprint4/helm/rick-api}" \
  --namespace "$NAMESPACE" --create-namespace

log_info "✅ Deployment completed successfully"