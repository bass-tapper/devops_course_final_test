import requests
import csv

def fetch_characters():
    url = "https://rickandmortyapi.com/api/character"
    filtered_characters = []

    while url:
        res = requests.get(url)
        res.raise_for_status()
        data = res.json()

        for char in data["results"]:
            if (
                char["species"] == "Human" and
                char["status"] == "Alive" and
                char["origin"]["name"].startswith("Earth")
            ):
                filtered_characters.append({
                    "name": char["name"],
                    "location": char["location"]["name"],
                    "image": char["image"]
                })

        url = data["info"]["next"]

    return filtered_characters

def save_to_csv(characters, filename="characters.csv"):
    with open(filename, mode="w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=["name", "location", "image"])
        writer.writeheader()
        writer.writerows(characters)

if __name__ == "__main__":
    print("Fetching characters...")
    characters = fetch_characters()
    save_to_csv(characters)
    print(f"Saved {len(characters)} characters to characters.csv")