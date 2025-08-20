#!/bin/bash
# Téléchargement des modèles GGUF

set -e

echo "📦 Téléchargement modèles GGUF..."

mkdir -p models

# TinyLlama pour classification
if [ ! -f "models/tinyllama-1.1b-q4.gguf" ]; then
    echo "⬇️ TinyLlama (classification)..."
    wget -O models/tinyllama-1.1b-q4.gguf \
        "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.q4_0.gguf"
fi

# Qwen2 pour résumés
if [ ! -f "models/qwen2-0.5b-q4.gguf" ]; then
    echo "⬇️ Qwen2 (résumés)..."
    wget -O models/qwen2-0.5b-q4.gguf \
        "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0.5b-instruct-q4_0.gguf"
fi

echo "✅ Modèles téléchargés"
ls -lh models/
