from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route("/healthcheck")
def healthcheck():
    return jsonify({"status": "healthy"})

@app.route("/fetch")
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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5555)