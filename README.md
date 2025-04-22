
# 🧪 Rick & Morty API Deployment - DevOps Final Project

This project demonstrates a complete DevOps workflow to build, containerize, deploy, and test a Flask-based Rick and Morty API using Docker, Helm, Kubernetes, and GitHub Actions.

---

## 📦 Project Structure

```
.
├── sprint1/                  # Raw Python script to fetch and save data
├── sprint2/app/              # Flask API + Docker setup
├── sprint3/yamls/            # Raw Kubernetes manifests
├── sprint4/helm/rick-api/    # Helm chart to deploy the app
└── sprint5/                  # README.md file of CI/CD overview
└── .github/workflows/        # GitHub Actions CI/CD pipeline
```

---

## 🚀 Features

- ✅ Python script fetches filtered Rick & Morty characters
- ✅ Flask API served via Gunicorn (port `5555`)
- ✅ Docker image built from `./sprint2/app`
- ✅ Deployed via Helm chart
- ✅ Runs in a temporary **Kind cluster** inside GitHub Actions
- ✅ CI tests health endpoint (`/healthcheck`) using port-forwarded service

---

## ⚙️ Technologies Used

- Python 3
- Flask
- Gunicorn
- Docker
- Kubernetes + Kind
- Helm
- GitHub Actions

---

## 🛠 Local Setup

To run locally:

```bash
# Set up virtual environment
cd sprint1
python3 -m venv venv
source venv/bin/activate
pip install -r ../sprint2/app/requirements.txt

# Run the script
python fetch_rick_and_morty.py
```

To build and test the container:

```bash
cd sprint2/app
docker build -t rick-api .
docker run -p 5555:5555 rick-api
curl http://localhost:5555/healthcheck
```

---

## 🧪 GitHub Actions CI/CD

### Triggered On:

- Every push to `main`
- Pull requests to `main`

### What It Does:

1. **Builds Docker image**
2. **Creates Kind cluster**
3. **Deploys Helm chart**
4. **Port-forwards service**
5. **Tests `/healthcheck` endpoint**
6. **Deletes Kind cluster on completion**

---

## ✅ Live Check: Health Endpoint

After deployment (CI or local):
```
GET /healthcheck → {"status": "healthy"}
```

---

## 📄 CI/CD Workflow Reference

See full pipeline:  
`.github/workflows/deploy.yml`

---

## 🧹 Cleanup (Local Dev)

```bash
minikube delete
kind delete cluster --name chart-testing
```

---

## 🤝 Contributions

PRs welcome — fork and improve, or try deploying it to GKE, EKS, or AKS as an advanced next step.

---

## 📛 License

MIT — do whatever you'd like.
