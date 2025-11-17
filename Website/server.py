from flask import Flask, request, jsonify, render_template
import json
import os

app = Flask(__name__)
POSITIONS_FILE = "positions.json"

def load_positions():
    if os.path.exists(POSITIONS_FILE):
        with open(POSITIONS_FILE, "r") as f:
            return json.load(f)
    return {}

def save_positions(data):
    with open(POSITIONS_FILE, "w") as f:
        json.dump(data, f, indent=2)

@app.route("/update_position", methods=["POST"])
def update_position():
    data = request.get_json()
    if not data:
        return "No JSON received", 400

    positions = load_positions()
    device = data["device"]

    # crea lista se non esiste
    if device not in positions:
        positions[device] = []

    positions[device].append({
        "lat": data["lat"],
        "lon": data["lon"],
        "timestamp": data["timestamp"]
    })

    save_positions(positions)
    return jsonify({"status": "ok"})

@app.route("/get_positions", methods=["GET"])
def get_positions():
    return jsonify(load_positions())

@app.route("/clear_positions", methods=["POST"])
def clear_positions():
    save_positions({})
    return jsonify({"status": "cleared"})

@app.route("/")
def index():
    return render_template("index.html")

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)

