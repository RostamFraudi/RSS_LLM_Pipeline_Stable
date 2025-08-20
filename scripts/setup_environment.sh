#!/bin/bash
# Setup environnement Python pour RSS LLM Pipeline Native

set -e

echo "🐍 Setup environnement Python..."

# Création environnement virtuel
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Environnement virtuel créé"
fi

# Activation
source venv/bin/activate

# Mise à jour pip
pip install --upgrade pip

# Installation dépendances
cd native_service
pip install -r requirements.txt
cd ..

echo "✅ Environnement Python configuré"
echo "   Activation: source venv/bin/activate"
