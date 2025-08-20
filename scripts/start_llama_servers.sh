#!/bin/bash
# Démarrage des serveurs llama.cpp

set -e

echo "🚀 Démarrage serveurs llama.cpp..."

# Vérifications
if [ ! -f "llama.cpp/build/bin/llama-server" ]; then
    echo "❌ llama-server non trouvé. Lancez setup_llama.sh"
    exit 1
fi

if [ ! -f "models/tinyllama-1.1b-q4.gguf" ]; then
    echo "❌ Modèles non trouvés. Lancez download_models.sh"
    exit 1
fi

# Fonction de nettoyage
cleanup() {
    echo "🛑 Arrêt des serveurs llama.cpp..."
    pkill -f "llama-server" || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# Démarrage serveur classification
echo "🦙 Démarrage TinyLlama (classification - port 8080)..."
./llama.cpp/build/bin/llama-server \
    -m "$(pwd)/models/tinyllama-1.1b-q4.gguf" \
    -ngl 32 \
    --host 0.0.0.0 \
    --port 8080 \
    --ctx-size 1024 \
    --threads 4 &

# Démarrage serveur résumés  
echo "🦙 Démarrage Qwen2 (résumés - port 8081)..."
./llama.cpp/build/bin/llama-server \
    -m "$(pwd)/models/qwen2-0.5b-q4.gguf" \
    -ngl 32 \
    --host 0.0.0.0 \
    --port 8081 \
    --ctx-size 2048 \
    --threads 4 &

# Attente chargement
echo "⏳ Attente chargement modèles..."
sleep 15

# Tests
echo "🧪 Tests de connectivité..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ TinyLlama prêt (port 8080)"
else
    echo "❌ TinyLlama non accessible"
fi

if curl -s http://localhost:8081/health > /dev/null; then
    echo "✅ Qwen2 prêt (port 8081)"
else
    echo "❌ Qwen2 non accessible"
fi

echo ""
echo "🎉 Serveurs llama.cpp opérationnels !"
echo "   Classification: http://localhost:8080"
echo "   Résumés:        http://localhost:8081"
echo ""
echo "💡 Ctrl+C pour arrêter"

# Attendre
wait
