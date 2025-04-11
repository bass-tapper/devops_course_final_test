
# 🐳 Sprint 2 – Dockerized Flask API

This is the second step in our full DevOps project.  
Now that we have a script that fetches and filters character data from the Rick and Morty API (Sprint 1), we will **expose that functionality via a RESTful API** and **containerize it using Docker**.

This step sets the foundation for deploying the app in any environment — whether local, on Kubernetes, or in the cloud.

---

## 🎯 Objective

Transform the data-fetching logic from Sprint 1 into a RESTful web service using Flask and package the app inside a Docker container.  
This makes your application portable, reproducible, and ready for deployment anywhere.

---

## ✅ Functional Requirements

1. **Create 2 Endpoints**  
   - `/fetch`: Returns the filtered characters in JSON format  
   - `/healthcheck`: Returns a health status: `{ "status": "healthy" }`

2. **Containerize the App**  
   - Use a lightweight Python base image  
   - Install dependencies from `requirements.txt`  
   - Expose and run the app on port 5000

---

## 📁 Sprint Structure

```
sprint2/
├── app/
│   ├── main.py                # Flask app with routing logic
│   ├── utils.py               # Character-fetching logic
│   └── __init__.py            # Optional (for modularization)
├── requirements.txt           # Flask + requests
├── Dockerfile                 # Docker image configuration
└── README.md                  # This file
```

---

## 🛠️ How to Run It

### 1. Build the Docker image

From the root folder where the `Dockerfile` is located:

```bash
docker build -t rick-api .
```

If the `Dockerfile` is inside `app/`, use:

```bash
docker build -t rick-api -f app/Dockerfile .
```

> Make sure the `COPY` instruction in the Dockerfile matches your folder layout.

---

### 2. Run the container

```bash
docker run -p 5000:5000 rick-api
```

This command maps the container's internal port `5000` to your local machine’s port `5000`.

---

### 3. Test the Endpoints

- `/healthcheck`  
  Check health status:  
  [http://localhost:5000/healthcheck](http://localhost:5000/healthcheck)  
  Expected response:  
  ```json
  {
    "status": "healthy"
  }
  ```

- `/fetch`  
  Get the filtered character list:  
  [http://localhost:5000/fetch](http://localhost:5000/fetch)  
  Expected response: a list of Rick and Morty characters matching your filter.

---

## 🧪 Notes

- You can modularize the code further by moving reusable logic into `utils.py`.
- Port `5000` is exposed by both the Flask app and Docker container.
- Flask is running in development mode for simplicity — use a WSGI server like Gunicorn for production.
- This service is stateless, which makes it ideal for container orchestration later.

---

## 💡 Why this is important? (For DevOps folks)

This step is critical for:
- 🧱 Building **microservices** that expose functionality via standard web protocols
- 🐳 Using **Docker** to ensure consistent environments across dev, staging, and production
- ⚙️ Creating an app that can easily be deployed, scaled, and integrated into CI/CD pipelines

In the real world, packaging your logic into a container is a must-have skill — and it’s exactly what gets your code one step closer to production.

