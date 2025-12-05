from flask import Flask, render_template, request, jsonify
import os
import json
import datetime
from pathlib import Path


app = Flask(__name__)

# Directorio para almacenamiento persistente
DATA_DIR = Path("/app/data")
DATA_DIR.mkdir(exist_ok=True)
MESSAGES_FILE = DATA_DIR / "messages.json"


def load_messages():
    """Carga mensajes desde el archivo persistente"""
    if MESSAGES_FILE.exists():
        with open(MESSAGES_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []


def save_messages(messages):
    """Guarda mensajes en el archivo persistente"""
    with open(MESSAGES_FILE, "w", encoding="utf-8") as f:
        json.dump(messages, f, ensure_ascii=False, indent=2)


@app.route("/")
def index():
    """Página principal"""
    return render_template("index.html")


@app.route("/health")
def health():
    """Endpoint de salud para Kubernetes"""
    return jsonify(
        {
            "status": "healthy",
            "timestamp": datetime.datetime.now().isoformat(),
            "hostname": os.getenv("HOSTNAME", "unknown"),
        }
    )


@app.route("/api/messages", methods=["GET"])
def get_messages():
    """Obtiene todos los mensajes almacenados"""
    messages = load_messages()
    return jsonify(messages)


@app.route("/api/messages", methods=["POST"])
def add_message():
    """Añade un nuevo mensaje"""
    data = request.get_json()
    if not data or "text" not in data:
        return jsonify({"error": "Se requiere el campo text"}), 400

    messages = load_messages()
    new_message = {
        "id": len(messages) + 1,
        "text": data["text"],
        "author": data.get("author", "Anónimo"),
        "timestamp": datetime.datetime.now().isoformat(),
        "hostname": os.getenv("HOSTNAME", "unknown"),
    }
    messages.append(new_message)
    save_messages(messages)

    return jsonify(new_message), 201


@app.route("/api/info")
def info():
    """Información del sistema"""
    return jsonify(
        {
            "app": "CloudEdu Services",
            "version": "1.0.0",
            "hostname": os.getenv("HOSTNAME", "unknown"),
            "environment": os.getenv("ENVIRONMENT", "production"),
            "total_messages": len(load_messages()),
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
