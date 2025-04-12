
# 🚀 Rick and Morty API – Universal Deployment & CI/CD Pipeline

This project provides a fully automated, cross-platform deployment experience using a single `deploy.sh` script and a GitHub Actions CI/CD workflow.

---

## 📦 Features

- 🔍 OS detection (macOS, Linux, WSL)
- 🔧 Automatic dependency checks & installation (if supported)
- 🐳 Starts Docker if it's not running
- ☸️ Auto-starts Minikube & enables Ingress
- 📈 Validates system resources (disk + RAM)
- 🧠 Smart CI detection (via `CI=true` or `--ci`)
- ⚙️ Helm chart-based deployment
- ✅ Supports local and CI/CD execution

---

## 🛠 Prerequisites (Handled Automatically)

- Docker (Desktop or daemon)
- Minikube
- kubectl
- Helm 3
- Python 3
- Git
- 5 GB free disk space
- 4 GB RAM

---

## 🧪 Usage

### 🔄 Make the script executable

```bash
chmod +x deploy.sh
```

### ✅ Local development

```bash
./deploy.sh --namespace dev --config config.env
```

### 🔄 Run in CI/CD (or simulate)

```bash
./deploy.sh --ci
```

---

## ⚙️ Configuration (`config.env`)

```env
DOCKER_IMAGE_NAME=rick-api
DOCKER_IMAGE_TAG=latest
HELM_RELEASE_NAME=rick
HELM_CHART_PATH=./sprint4/helm/rick-api
NAMESPACE=default
```

---

## 🧠 CI/CD Setup – GitHub Actions

Place this in `.github/workflows/deploy.yml`:

```yaml
name: Deploy Rick and Morty API

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker
        uses: docker/setup-buildx-action@v2

      - name: Set up Kubernetes (KinD)
        uses: helm/kind-action@v1

      - name: Set up Helm
        uses: azure/setup-helm@v3

      - name: Run deployment script
        run: |
          chmod +x deploy.sh
          ./deploy.sh --ci
```

---

## 🙋 FAQ

### 🛑 What if Docker or Minikube isn’t running?
This script will detect and attempt to start them.

### 📦 Can I run this on GitHub Actions, GitLab CI, Jenkins?
Yes. The script checks for `CI=true` or `--ci`, skipping local-only steps.

---

## 🧼 Cleanup

To reset Docker env:
```bash
eval $(minikube docker-env -u)
```

To delete Minikube cluster:
```bash
minikube delete
```

---

## 🧙‍♂️ Pro Tips

- Use `--debug` to print more verbose output
- Add `--dry-run` to simulate without applying changes

---

## ✅ You’re Good to Go!

Run `./deploy.sh` and enjoy hands-free deployment! 🎉
