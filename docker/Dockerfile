FROM python:3.12-slim

# Prevent Python from writing .pyc files and enable unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first (better layer caching)
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY app/ .

# Copy Gunicorn config
COPY docker/gunicorn.conf.py .

# Run as non-root user (good security habit)
RUN useradd -m appuser
USER appuser

# Run with Gunicorn (production WSGI server)
CMD ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]
