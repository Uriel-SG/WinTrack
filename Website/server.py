import os
import sys
import json
import logging
from flask import Flask, request, jsonify, render_template
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
POSITIONS_FILE = "positions.json"

API_KEY = os.environ.get("WINTRACK_API_KEY")
if not API_KEY:
    logging.error(
        "Variabile WINTRACK_API_KEY mancante. Il server non può avviarsi senza API key."
    )
    sys.exit(1)

limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["50 per 10 minutes"]  # Limite globale
)

def load_positions():
    if os.path.exists(POSITIONS_FILE):
        with open(POSITIONS_FILE, "r") as f:
            return json.load(f)
    return {}

def save_positions(data):
    with open(POSITIONS_FILE, "w") as f:
        json.dump(data, f, indent=2)

@app.route("/update_position", methods=["POST"])
@limiter.limit("20 per minute")
def update_position():
    incoming_key = request.headers.get("X-API-Key")
    if incoming_key != API_KEY:
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON received"}), 400

    device = data.get("device")
    lat = data.get("lat")
    lon = data.get("lon")
    timestamp = data.get("timestamp")

    # Controllo campi base
    if device is None or timestamp is None:
        return jsonify({"error": "Missing fields"}), 400

    # Validazione lat/lon (senza la quale l'app crashava)
    try:
        lat_f = float(lat)
        lon_f = float(lon)

        # Scarta NaN o infinito
        if not (abs(lat_f) <= 90 and abs(lon_f) <= 180):
            raise ValueError("Coordinates out of valid range")
    except Exception:
        # Logga ma NON blocca e NON salva
        logging.warning(f"Coordinate non valide ricevute da device {device}: lat={lat}, lon={lon}")
        return jsonify({"status": "ignored"}), 200

    # Se i valori sono validi, salva
    positions = load_positions()
    positions.setdefault(device, [])
    positions[device].append({"lat": lat_f, "lon": lon_f, "timestamp": timestamp})
    save_positions(positions)

    return jsonify({"status": "ok"}), 200


@app.route("/get_positions", methods=["GET"])
def get_positions():
    return jsonify(load_positions()), 200

@app.route("/clear_positions", methods=["POST"])
def clear_positions():
    save_positions({})
    return jsonify({"status": "cleared"}), 200

@app.route("/")
def index():
    return render_template("index.html"), 200

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)



