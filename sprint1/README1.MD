# 🚀 Sprint 1 – Rick & Morty Data Fetch Script

This is the first step in a complete DevOps project that involves scripting, containerization, deployment to Kubernetes, Helm chart packaging, and GitHub Actions automation.

In **Sprint 1**, we focus on building a **simple yet powerful Python script** that interacts with a public API and transforms data into a CSV format — a task common in data workflows, testing pipelines, or backend preprocessing services.

---

## 🎯 Objective

Create a Python script that:

- Calls the [Rick and Morty API](https://rickandmortyapi.com/documentation)
- Filters characters using specific criteria
- Extracts their details
- Saves the results in a structured CSV file

This will serve as the foundation for future steps like turning this logic into a web service, deploying it in the cloud, and automating its lifecycle.

---

## ✅ Functional Requirements

1. **API Filtering**  
   Retrieve all characters where:
   - `species = Human`
   - `status = Alive`
   - `origin.name` starts with `"Earth"`

2. **Extract Data**  
   For each valid character, extract:
   - `name`
   - `location.name`
   - `image` (URL to avatar)

3. **CSV Output Format**  
   Save this data into a CSV file named `characters.csv`:

   ```csv
   Name,Location,Image
   Rick Sanchez,Earth,https://rickandmortyapi.com/api/character/avatar/1.jpeg

   Sprint Structure
   sprint1/
├── fetch_rick_and_morty.py       # Python script that fetches and filters character data
├── characters.csv                # Output CSV file (created on run)
└── requirements.txt              # Python dependency: requests

How to Run It:

1. Create & activate a virtual environment using bash:
    
    cd sprint1
    python3 -m venv venv
    source venv/bin/activate

2. Install dependencies using bash:
    pip install -r requirements.txt
    
3. Run the script using bash:
    python fetch_rick_and_morty.py

4. Check the output

A file named characters.csv will be created in the same directory.
It will contain the filtered characters and their details.


🧪 Notes
	•	Pagination is automatically handled using the next field in the API response.
	•	Filtering is done locally (client-side) for flexibility.
	•	The script uses the open Rick & Morty API — no token or authentication needed.


💡 Why this is important? (For DevOps folks)

This script lays the groundwork for:
	•	Microservice logic: business logic that can later be exposed via HTTP
	•	Automation: useful in CI/CD data tasks (ETL, test data, reporting)
	•	Containerization: clean structure makes it easy to package in a Docker image

By starting cleanly with a functional script, we ensure future layers (Docker, Kubernetes, CI/CD) will be modular and maintainable.