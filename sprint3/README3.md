
# ☸️ Sprint 3 – Kubernetes Deployment (Minikube)

This is the third step in our full DevOps project.  
Now that the application is containerized, we will deploy it on a **local Kubernetes cluster using Minikube**.

This brings your app into a production-like orchestration environment, giving it high availability, service discovery, and real-world infrastructure behavior.

---

## 🎯 Objective

Use Kubernetes to deploy the `rick-api` Docker container locally, exposing it through an Ingress so it can be accessed via a browser or curl.

---

## ✅ Functional Requirements

1. Create Kubernetes manifests:
   - `deployment.yaml`
   - `service.yaml`
   - `ingress.yaml`

2. Use `kubectl apply` to deploy all the resources.

3. Access the app at:  
   [http://rick.local](http://rick.local)

---

## 📁 Sprint Structure

```
sprint3/
├── yamls/
│   ├── deployment.yaml        # Creates 2 replicas of the rick-api container
│   ├── service.yaml           # Exposes the deployment inside the cluster
│   └── ingress.yaml           # Exposes the service externally via hostname
└── README.md                  # This file
```

---

## 🛠️ How to Deploy with Minikube

### 1. Start Minikube

```bash
minikube start
minikube addons enable ingress
```

### 2. Point Docker to Minikube’s environment

This allows you to build images directly accessible to Minikube:

```bash
eval $(minikube docker-env)
```

### 3. Build the Docker image

```bash
docker build -t rick-api -f ../sprint2/app/Dockerfile ../sprint2/app
```

> This assumes your Dockerfile is inside `sprint2/app/`

### 4. Apply Kubernetes manifests

```bash
kubectl apply -f yamls/
```

### 5. Add a local DNS entry for ingress

Append this to your `/etc/hosts` file:

```bash
sudo -- sh -c "echo '$(minikube ip) rick.local' >> /etc/hosts"
```

### 6. Test in browser

Visit:  
[http://rick.local](http://rick.local)  
You should see the JSON response from `/fetch`.

---

## 🧪 Notes

- You can check pod and service status with:
  ```bash
  kubectl get all
  ```

- Ingress is exposed on Minikube's IP, routed via hostname `rick.local`.

- Replicas are set to 2 for load balancing and high availability.

---

## 💡 Why this is important? (For DevOps folks)

- Kubernetes is the **standard for cloud-native deployment**
- It supports **scaling**, **self-healing**, and **rolling updates**
- Understanding how to expose services and manage clusters is essential for any DevOps engineer

By deploying locally using Minikube, you get full control and visibility over how your container behaves in production-like conditions — without the cloud bill.

