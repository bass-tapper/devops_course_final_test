from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route("/healthcheck", methods=["GET"])
def healthcheck():
    return jsonify({"status": "healthy"})

@app.route("/fetch", methods=["GET"])
def fetch_characters():
    url = "https://rickandmortyapi.com/api/character"
    filtered = []

    while url:
        res = requests.get(url)
        res.raise_for_status()
        data = res.json()
        for char in data["results"]:
            if (
                char["species"] == "Human"
                and char["status"] == "Alive"
                and char["origin"]["name"].startswith("Earth")
            ):
                filtered.append({
                    "name": char["name"],
                    "location": char["location"]["name"],
                    "image": char["image"]
                })
        url = data["info"]["next"]

    return jsonify(filtered)