import os
import sys
import json
import logging
from flask import Flask, request, jsonify, render_template, Response
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_httpauth import HTTPBasicAuth

# Configurazione e Inizializzazione
app = Flask(__name__)
auth = HTTPBasicAuth()

POSITIONS_FILE = "positions.json"

# Variabili d'Ambiente
API_KEY = os.environ.get("WINTRACK_API_KEY")
AUTH_USERNAME = os.environ.get("WINTRACK_AUTH_USER")
AUTH_PASSWORD = os.environ.get("WINTRACK_AUTH_PASS")

if not API_KEY or not AUTH_USERNAME or not AUTH_PASSWORD:
    logging.error(
        "Variabili d'ambiente mancanti: WINTRACK_API_KEY, WINTRACK_AUTH_USER, e WINTRACK_AUTH_PASS sono richieste per l'avvio sicuro."
    )
    sys.exit(1)

# Rate Limiter
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=[]
)

# Funzioni di Autenticazione Basic
@auth.verify_password
def verify_password(username, password):
    """Verifica le credenziali Basic Auth."""
    if username == AUTH_USERNAME and password == AUTH_PASSWORD:
        return username
    return None

# Funzioni di I/O
def load_positions():
    if os.path.exists(POSITIONS_FILE):
        try:
            with open(POSITIONS_FILE, "r") as f:
                return json.load(f)
        except json.JSONDecodeError:
            logging.warning("File positions.json corrotto. Ritorno un JSON vuoto.")
            return {}
    return {}

def save_positions(data):
    with open(POSITIONS_FILE, "w") as f:
        json.dump(data, f, indent=2)


@app.route("/update_position", methods=["POST"])
@auth.login_required
@limiter.limit("20 per minute")
def update_position():
    incoming_key = request.headers.get("X-API-Key")
    if incoming_key != API_KEY:
        return jsonify({"error": "Invalid API Key"}), 403 

    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON received"}), 400

    device = data.get("device")
    lat = data.get("lat")
    lon = data.get("lon")
    timestamp = data.get("timestamp")

    if device is None or lat is None or lon is None or timestamp is None:
        return jsonify({"error": "Missing fields"}), 400

    try:
        float(lat)
        float(lon)
    except (ValueError, TypeError):
        return jsonify({"error": "Latitude and longitude must be valid numbers"}), 400

    positions = load_positions()
    positions.setdefault(device, [])
    positions[device].append({"lat": float(lat), "lon": float(lon), "timestamp": timestamp})
    save_positions(positions)

    return jsonify({"status": "ok"}), 200

@app.route("/get_positions", methods=["GET"])
@auth.login_required
def get_positions():
    return jsonify(load_positions()), 200

@app.route("/clear_positions", methods=["POST"])
@auth.login_required
def clear_positions():
    """Mantiene solo l'ultimo elemento della lista per ogni PC."""
    positions = load_positions()
    
    cleaned_positions = {}
    for device, entries in positions.items():
        if isinstance(entries, list) and len(entries) > 0:
            # Prendi l'ultimo elemento e lo mette in una nuova lista
            cleaned_positions[device] = [entries[-1]]
        else:
            # Se la lista è  vuota, mantienila tale
            cleaned_positions[device] = []
            
    save_positions(cleaned_positions)
    return jsonify({"status": "cleared_keep_last"}), 200

@app.route("/")
def index():
    return render_template("index.html"), 200

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
