
# 🧪 Sprint 5 – CI/CD Automation

This sprint focuses on fully automating the deployment of the Rick and Morty API using GitHub Actions.

While this folder doesn't contain application code, it anchors the documentation and logic related to CI/CD.

---

## 🔧 What’s Automated in Sprint 5

- Builds a Docker image from the Flask app in `sprint2/app`
- Spins up a Kubernetes-in-Docker (Kind) cluster
- Deploys the app using Helm from `sprint4/helm/rick-api`
- Port-forwards the service for testing
- Tests the `/healthcheck` endpoint
- Cleans up the cluster after the run

---

## 📦 Relevant Files

| File/Folder                             | Purpose                                               |
|----------------------------------------|-------------------------------------------------------|
| `.github/workflows/deploy.yml`         | GitHub Actions CI/CD pipeline definition              |
| `reset-and-deploy.sh`                  | Local script to test the deployment manually          |
| `README_DEPLOY.md`                     | In-depth documentation of the pipeline steps          |

---

## 🚀 How It Works

Every time a push is made to the `main` branch:
1. A Kind cluster is created
2. The app is containerized and deployed
3. The `/healthcheck` endpoint is validated via `curl`
4. The cluster is deleted on completion

---

## ✅ Want to Test It?

To test locally without GitHub Actions:

```bash
./reset-and-deploy.sh
```

Or commit and push to `main` to watch it run live in [GitHub Actions](https://github.com/your-repo/actions).

---

📌 This sprint is all about glue — not code!

