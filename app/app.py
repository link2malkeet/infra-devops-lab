import os
import json
import sys
import signal
import uuid
from datetime import datetime, timezone
from flask import Flask, jsonify, request, g
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

# Prometheus metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

# Graceful shutdown flag
shutdown_flag = False

def log(level: str, event: str, **fields):
    """Structured JSON logging for production"""
    payload = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "level": level,
        "event": event,
        "service": "infra-devops-lab",
        **fields,
    }
    # Include request ID if available
    if hasattr(g, 'request_id'):
        payload["request_id"] = g.request_id
    print(json.dumps(payload), file=sys.stdout, flush=True)

def setup_security_headers(response):
    """Add security headers to all responses"""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    # Remove server header for security
    response.headers.pop('Server', None)
    return response

@app.before_request
def before_request():
    """Set up request context"""
    # Generate request ID for distributed tracing
    g.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
    g.start_time = time.time()
    
    # Check for graceful shutdown
    if shutdown_flag:
        return jsonify(error="Service is shutting down"), 503

@app.after_request
def after_request(response):
    """Log requests and add security headers"""
    # Calculate request duration
    duration = time.time() - g.start_time if hasattr(g, 'start_time') else 0
    
    # Log request
    log(
        "info",
        "http_request",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr,
        user_agent=request.headers.get("User-Agent", ""),
        status_code=response.status_code,
        duration_ms=round(duration * 1000, 2),
    )
    
    # Record metrics
    endpoint = request.endpoint or request.path
    http_requests_total.labels(
        method=request.method,
        endpoint=endpoint,
        status=response.status_code
    ).inc()
    http_request_duration_seconds.labels(
        method=request.method,
        endpoint=endpoint
    ).observe(duration)
    
    # Add request ID to response headers
    response.headers['X-Request-ID'] = g.request_id
    
    # Add security headers
    response = setup_security_headers(response)
    
    return response

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify(error="Not found", path=request.path), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    log("error", "internal_server_error", error=str(error))
    return jsonify(error="Internal server error"), 500

@app.errorhandler(Exception)
def handle_exception(e):
    """Handle all unhandled exceptions"""
    log("error", "unhandled_exception", error=str(e), error_type=type(e).__name__)
    return jsonify(error="Internal server error"), 500

@app.get("/")
def home():
    """Root endpoint"""
    return jsonify(
        status="ok",
        service="infra-devops-lab",
        version=os.getenv("APP_VERSION", "unknown")
    )

@app.get("/healthz")
def healthz():
    """Liveness probe: process is alive"""
    if shutdown_flag:
        return jsonify(status="shutting_down"), 503
    return jsonify(status="ok")

@app.get("/readyz")
def readyz():
    """Readiness probe: service is ready to accept traffic"""
    if shutdown_flag:
        return jsonify(status="not_ready", reason="shutting_down"), 503
    
    # Add dependency checks here (database, external services, etc.)
    # For now, just check if we're not shutting down
    return jsonify(status="ready")

@app.get("/metrics")
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    global shutdown_flag
    log("info", "shutdown_signal_received", signal=signum)
    shutdown_flag = True
    # Give time for in-flight requests to complete
    # Gunicorn will handle the actual shutdown

# Register signal handlers for graceful shutdown
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

if __name__ == "__main__":
    port = os.getenv("APP_PORT")
    if not port:
        log("error", "startup_failed", reason="missing_APP_PORT")
        raise RuntimeError("APP_PORT env var is required")

    log("info", "startup", port=int(port), version=os.getenv("APP_VERSION", "dev"))
    app.run(host="0.0.0.0", port=int(port))
