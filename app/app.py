import os
import json
import sys
from datetime import datetime, timezone
from flask import Flask, jsonify, request

app = Flask(__name__)

def log(level: str, event: str, **fields):
    payload = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "level": level,
        "event": event,
        "service": "infra-devops-lab",
        **fields,
    }
    print(json.dumps(payload), file=sys.stdout, flush=True)

@app.before_request
def _log_request():
    log(
        "info",
        "http_request",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr,
        user_agent=request.headers.get("User-Agent"),
    )

@app.get("/")
def home():
    return jsonify(status="ok", service="infra-devops-lab")

@app.get("/healthz")
def healthz():
    # Liveness probe: process is alive
    return jsonify(status="ok")

@app.get("/readyz")
def readyz():
    # Readiness probe: for now same as health, later we'll add dependency checks
    return jsonify(status="ready")

if __name__ == "__main__":
    port = os.getenv("APP_PORT")
    if not port:
        log("error", "startup_failed", reason="missing_APP_PORT")
        raise RuntimeError("APP_PORT env var is required")

    log("info", "startup", port=int(port))
    app.run(host="0.0.0.0", port=int(port))
