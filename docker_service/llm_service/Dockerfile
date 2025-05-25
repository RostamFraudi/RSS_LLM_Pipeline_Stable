FROM python:3.10-slim

# Installation des dépendances système + curl pour healthcheck
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Installation des dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code
COPY app.py .

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# Exposition du port
EXPOSE 5000

# Commande de démarrage
CMD ["python", "app.py"]