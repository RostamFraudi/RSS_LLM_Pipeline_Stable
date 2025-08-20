#!/bin/bash
# RSS LLM Pipeline Native - Démarrage
set -e

echo "🚀 Démarrage RSS LLM Pipeline Native"
echo "===================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Activation environnement
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
else
    echo "❌ Environnement Python non trouvé"
    echo "   Lancez: ./install.sh"
    exit 1
fi

# Variables ports
CLASSIFICATION_PORT=8080
SUMMARY_PORT=8081
API_PORT=15000

# Fonction nettoyage
cleanup() {
    echo "🛑 Arrêt des services..."
    pkill -f "llama-server" || true
    pkill -f "python.*app.py" || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# Vérifications
if [ ! -f "llama.cpp/build/bin/llama-server" ]; then
    echo "❌ llama-server non trouvé"
    echo "   Relancez: ./install.sh"
    exit 1
fi

# Recherche modèles disponibles
TINYLLAMA_MODEL=$(find models/ -name "*tinyllama*" -o -name "*1.1b*" | head -n1 2>/dev/null || echo "")
QWEN2_MODEL=$(find models/ -name "*qwen2*" -o -name "*0.5b*" | head -n1 2>/dev/null || echo "")

if [ -z "$TINYLLAMA_MODEL" ] && [ -z "$QWEN2_MODEL" ]; then
    echo "⚠️  Aucun modèle trouvé dans models/"
    echo "   Téléchargez les modèles GGUF requis"
    echo "   Voir: docs/INSTALL.md"
fi

# Démarrage services
echo "🦙 Démarrage llama.cpp servers..."

if [ -n "$TINYLLAMA_MODEL" ]; then
    echo "  📚 TinyLlama: $TINYLLAMA_MODEL"
    cd llama.cpp
    ./build/bin/llama-server -m "../$TINYLLAMA_MODEL" -ngl 32 --host 0.0.0.0 --port $CLASSIFICATION_PORT --ctx-size 1024 &
    cd ..
fi

if [ -n "$QWEN2_MODEL" ]; then
    echo "  📝 Qwen2: $QWEN2_MODEL"
    cd llama.cpp
    ./build/bin/llama-server -m "../$QWEN2_MODEL" -ngl 32 --host 0.0.0.0 --port $SUMMARY_PORT --ctx-size 2048 &
    cd ..
fi

sleep 10

# API Python
if [ -f "native_service/app.py" ]; then
    echo "🐍 Démarrage API Python..."
    cd native_service
    python app.py &
    cd ..
fi

echo ""
echo "🎉 Services démarrés !"
echo "  🔗 API Health: http://localhost:$API_PORT/health"
echo "  🦙 Classification: http://localhost:$CLASSIFICATION_PORT"
echo "  📝 Résumés: http://localhost:$SUMMARY_PORT"
echo ""
echo "💡 Ctrl+C pour arrêter"

# Attendre
wait
