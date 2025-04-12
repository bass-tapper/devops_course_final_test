#!/bin/bash

# ==============================================================================
# Rick and Morty API - Automated Deployment Script
# ==============================================================================
# This script automates the entire workflow for the Rick and Morty API project:
# - Environment setup (directories and dependencies)
# - Docker image building
# - Helm chart deployment
# - Git repository setup
#
# Usage: ./deploy.sh
# Make sure to run 'chmod +x deploy.sh' before executing
# ==============================================================================

# Set shell options for error handling
set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Return value of a pipeline is the status of the last command

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# ==============================================================================
# OS Detection and Package Management
# ==============================================================================

# Detect OS type
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

# Detect package manager for Linux
detect_pkg_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

if [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "wsl" ]]; then
    PKG_MANAGER=$(detect_pkg_manager)
fi

# ==============================================================================
# Utility Functions
# ==============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

prompt_yes_no() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or y or no or n.";;
        esac
    done
}

# Install prerequisites based on OS
install_prerequisite() {
    local tool=$1
    local installed=false
    
    log_info "Attempting to install $tool..."
    
    case "$OS_TYPE" in
        linux|wsl)
            case "$PKG_MANAGER" in
                apt)
                    case "$tool" in
                        python3)
                            sudo apt-get update && sudo apt-get install -y python3 python3-pip
                            ;;
                        pip3)
                            sudo apt-get update && sudo apt-get install -y python3-pip
                            ;;
                        docker)
                            sudo apt-get update
                            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                            sudo apt-get update
                            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                            sudo usermod -aG docker $USER
                            log_warn "You may need to log out and back in for Docker group changes to take effect."
                            ;;
                        minikube)
                            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                            sudo install minikube-linux-amd64 /usr/local/bin/minikube
                            rm minikube-linux-amd64
                            ;;
                        kubectl)
                            sudo apt-get update
                            sudo apt-get install -y apt-transport-https ca-certificates curl
                            sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
                            echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
                            sudo apt-get update
                            sudo apt-get install -y kubectl
                            ;;
                        helm)
                            curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
                            sudo apt-get install apt-transport-https --yes
                            echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
                            sudo apt-get update
                            sudo apt-get install -y helm
                            ;;
                        git)
                            sudo apt-get update && sudo apt-get install -y git
                            ;;
                        *)
                            log_error "Don't know how to install $tool on this system."
                            return 1
                            ;;
                    esac
                    ;;
                dnf|yum)
                    case "$tool" in
                        python3)
                            sudo $PKG_MANAGER install -y python3 python3-pip
                            ;;
                        pip3)
                            sudo $PKG_MANAGER install -y python3-pip
                            ;;
                        docker)
                            sudo $PKG_MANAGER install -y yum-utils
                            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                            sudo $PKG_MANAGER install -y docker-ce docker-ce-cli containerd.io
                            sudo systemctl start docker
                            sudo systemctl enable docker
                            sudo usermod -aG docker $USER
                            log_warn "You may need to log out and back in for Docker group changes to take effect."
                            ;;
                        minikube)
                            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                            sudo install minikube-linux-amd64 /usr/local/bin/minikube
                            rm minikube-linux-amd64
                            ;;
                        kubectl)
                            cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
                            sudo $PKG_MANAGER install -y kubectl
                            ;;
                        helm)
                            curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
                            chmod 700 get_helm.sh
                            ./get_helm.sh
                            rm get_helm.sh
                            ;;
                        git)
                            sudo $PKG_MANAGER install -y git
                            ;;
                        *)
                            log_error "Don't know how to install $tool on this system."
                            return 1
                            ;;
                    esac
                    ;;
                pacman)
                    case "$tool" in
                        python3)
                            sudo pacman -Sy --noconfirm python python-pip
                            ;;
                        pip3)
                            sudo pacman -Sy --noconfirm python-pip
                            ;;
                        docker)
                            sudo pacman -Sy --noconfirm docker
                            sudo systemctl start docker
                            sudo systemctl enable docker
                            sudo usermod -aG docker $USER
                            log_warn "You may need to log out and back in for Docker group changes to take effect."
                            ;;
                        minikube)
                            sudo pacman -Sy --noconfirm minikube
                            ;;
                        kubectl)
                            sudo pacman -Sy --noconfirm kubectl
                            ;;
                        helm)
                            sudo pacman -Sy --noconfirm helm
                            ;;
                        git)
                            sudo pacman -Sy --noconfirm git
                            ;;
                        *)
                            log_error "Don't know how to install $tool on this system."
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    log_error "Unsupported package manager on Linux. Please install $tool manually."
                    return 1
                    ;;
            esac
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                log_info "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [ $? -ne 0 ]; then
                    log_error "Failed to install Homebrew. Please install it manually."
                    return 1
                fi
            fi
            
            case "$tool" in
                python3)
                    brew install python
                    ;;
                pip3)
                    brew install python
                    ;;
                docker)
                    log_info "For macOS, please install Docker Desktop from https://www.docker.com/products/docker-desktop"
                    return 1
                    ;;
                minikube)
                    brew install minikube
                    ;;
                kubectl)
                    brew install kubectl
                    ;;
                helm)
                    brew install helm
                    ;;
                git)
                    brew install git
                    ;;
                *)
                    log_error "Don't know how to install $tool on macOS."
                    return 1
                    ;;
            esac
            ;;
        *)
            log_error "Unsupported operating system. Please install $tool manually."
            return 1
            ;;
    esac
    
    # Check if installation was successful
    if command -v $tool &> /dev/null; then
        log_info "$tool was successfully installed."
        return 0
    else
        log_warn "Automatic installation of $tool may have failed. Please install it manually."
        return 1
    fi
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_warn "$1 is required but not installed."
        
        if prompt_yes_no "Would you like to install $1 automatically?"; then
            if ! install_prerequisite $1; then
                log_error "Failed to install $1. Please install it manually and then run this script again."
                exit 1
            fi
        else
            log_error "Please install $1 manually and then run this script again."
            exit 1
        fi
    fi
}

check_exit_status() {
    if [ $1 -ne 0 ]; then
        log_error "$2 failed with exit code $1"
        exit $1
    fi
}
# ==============================================================================
# ==============================================================================
# 1. Environment Setup
# ==============================================================================

setup_environment() {
    log_info "Starting environment setup..."
    log_info "Detected operating system: $OS_TYPE"
    if [[ "$OS_TYPE" == "linux" || "$OS_TYPE" == "wsl" ]]; then
        log_info "Detected package manager: $PKG_
    # Verify environment status
    log_info "Verifying environment status..."
    
    # Check Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check Minikube status
    if ! minikube status &> /dev/null; then
        log_warn "Minikube is not running. Will attempt to start it during deployment."
    else
        log_info "Minikube is running."
    fi
    
    # Create necessary directories if they don't exist
    for dir in "sprint2/app" "sprint4/helm"; do
        if [ ! -d "$dir" ]; then
            log_warn "Directory $dir does not exist. Creating..."
            mkdir -p "$dir"
        fi
    done
    
    # Set up Python virtual environment if not exists
    if [ ! -d "venv" ]; then
        log_info "Creating Python virtual environment..."
        python3 -m venv venv
        check_exit_status $? "Creating virtual environment"
    else
        log_info "Virtual environment already exists."
    fi
    
    # Activate virtual environment and install dependencies
    log_info "Activating virtual environment and installing dependencies..."
    source venv/bin/activate
    
    # Check if requirements.txt exists in project root, otherwise create it
    if [ ! -f "requirements.txt" ]; then
        if [ -f "sprint2/app/requirements.txt" ]; then
            cp sprint2/app/requirements.txt .
        else
            echo "Flask" > requirements.txt
            echo "requests" >> requirements.txt
            echo "gunicorn" >> requirements.txt
            log_warn "Created requirements.txt with basic dependencies."
        fi
    fi
    
    pip3 install -r requirements.txt
    check_exit_status $? "Installing Python dependencies"
    
    log_info "Environment setup completed successfully."
}

# ==============================================================================
# 2. Docker Operations
# ==============================================================================

build_docker_image() {
    log_info "Starting Docker operations..."
    
    # Configure Docker to use Minikube's Docker daemon
    log_info "Configuring Docker to use Minikube's Docker daemon..."
    eval $(minikube docker-env)
    check_exit_status $? "Configuring Minikube Docker environment"
    
    # Build Docker image
    log_info "Building Docker image: rick-api..."
    docker build -t rick-api ./sprint2/app
    check_exit_status $? "Building Docker image"
    
    # Verify image was created
    if docker images | grep -q "rick-api"; then
        log_info "Docker image rick-api built successfully."
    else
        log_error "Docker image verification failed."
        exit 1
    fi
}

# ==============================================================================
# 3. Helm Deployment
# ==============================================================================

deploy_helm_chart() {
    log_info "Starting Helm deployment..."
    
    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
        log_warn "Minikube is not running. Starting Minikube..."
        minikube start
        check_exit_status $? "Starting Minikube"
    fi
    
    # Check for existing deployment
    if helm list | grep -q "rick"; then
        log_warn "Existing 'rick' deployment found. Will upgrade the deployment."
        log_info "If you want to start fresh, run: helm uninstall rick"
    else
        log_info "No existing deployment found. Will create a new deployment."
    fi
    
    # Deploy Helm chart
    log_info "Deploying Rick API using Helm chart..."
    helm upgrade --install rick ./sprint4/helm/rick-api
    check_exit_status $? "Deploying Helm chart"
    
    # Wait for pods to be ready
    log_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=rick-api --timeout=120s
    
    # Check deployment status
    if kubectl get pods -l app=rick-api | grep -q "Running"; then
        log_info "Helm deployment successful. Pods are running."
        
        # Verify health check endpoint
        log_info "Verifying health check endpoint..."
        # Using port-forwarding to access the health check
        kubectl port-forward svc/rick 5000:80 &
        PORT_FORWARD_PID=$!
        sleep 5
        
        HEALTH_CHECK=$(curl -s http://localhost:5000/healthcheck)
        kill $PORT_FORWARD_PID
        
        if [[ $HEALTH_CHECK == *"healthy"* ]]; then
            log_info "Health check successful: $HEALTH_CHECK"
        else
            log_warn "Health check verification failed or returned unexpected result."
        fi
    else
        log_error "Helm deployment verification failed. Pods are not running properly."
        kubectl get pods -l app=rick-api
        exit 1
    fi
}

# ==============================================================================
# 4. Version Control
# ==============================================================================

setup_git_repository() {
    log_info "Setting up version control..."
    
    # Initialize Git repository if it doesn't exist
    if [ ! -d ".git" ]; then
        log_info "Initializing Git repository..."
        git init
        check_exit_status $? "Initializing Git repository"
        
        # Set main as the default branch
        git branch -m main
    else
        log_info "Git repository already initialized."
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        log_info "Creating .gitignore file..."
        cat > .gitignore << EOF
.DS_Store
venv/
*.zip
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg
EOF
        check_exit_status $? "Creating .gitignore file"
    fi
    
    # Add and commit all files
    log_info "Adding files to Git repository..."
    git add .
    check_exit_status $? "Adding files to Git"
    
    # Commit changes if there are staged changes
    if git diff --cached --quiet; then
        log_info "No changes to commit."
    else
        log_info "Committing changes..."
        git commit -m "Initial commit: Adding project files"
        check_exit_status $? "Committing changes"
    fi
    
    log_info "Version control setup completed successfully."
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    log_info "==============================================="
    log_info "   RICK AND MORTY API DEPLOYMENT STARTED      "
    log_info "==============================================="
    
    setup_environment
    build_docker_image
    deploy_helm_chart
    setup_git_repository
    
    log_info "==============================================="
    log_info "   DEPLOYMENT COMPLETED SUCCESSFULLY          "
    log_info "==============================================="
    
    log_info "You can access the application at http://rick.local/fetch"
    log_info "For health check, visit http://rick.local/healthcheck"
    
    # Display additional information about accessing the service
    log_info "==============================================="
    log_info "   ADDITIONAL ACCESS INFORMATION              "
    log_info "==============================================="
    log_info "You can also access the service via port forwarding:"
    log_info "  kubectl port-forward svc/rick 5000:80"
    log_info "Then visit: http://localhost:5000/fetch or http://localhost:5000/healthcheck"
    
    log_info "To check the deployment status:"
    log_info "  kubectl get pods -l app=rick-api"
    log_info "  kubectl get svc rick"
}

# Execute main function
main

