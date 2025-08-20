#!/bin/bash
# Script de démarrage RSS LLM Pipeline Native v3.1
# CORRECTION: Node-RED sur port 18880 avec accès direct

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
LLAMA_DIR="$SCRIPT_DIR/llama.cpp"
MODELS_DIR="$SCRIPT_DIR/models"
NODERED_DIR="$SCRIPT_DIR/node_red_native"

echo "🚀 Démarrage RSS LLM Pipeline Native v3.1"
echo "=========================================="

# Fonction nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt des services..."
    pkill -f "llama-server" 2>/dev/null || true
    pkill -f "python.*app.py" 2>/dev/null || true
    pkill -f "node-red" 2>/dev/null || true
    echo "✅ Services arrêtés"
    exit 0
}
trap cleanup SIGINT SIGTERM

# Activation environnement Python
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
    echo "✅ Environnement Python activé"
else
    echo "❌ Environnement Python non trouvé"
    echo "   💡 Relancez: ./install.sh"
    exit 1
fi

# Variables ports - NODE-RED 18880
CLASSIFICATION_PORT=8080
SUMMARY_PORT=8081
API_PORT=15000
NODERED_PORT=18880

echo "📍 Ports configurés:"
echo "   • Classification: $CLASSIFICATION_PORT"
echo "   • Résumés:       $SUMMARY_PORT"
echo "   • API Python:    $API_PORT"
echo "   • Node-RED:      $NODERED_PORT"

# Vérifications pré-démarrage
echo ""
echo "🔍 Vérifications..."

# Modèles
for model in "tinyllama-1.1b-q4.gguf" "qwen2-0.5b-q4.gguf"; do
    if [ ! -f "$MODELS_DIR/$model" ]; then
        echo "❌ Modèle manquant: $model"
        echo "   💡 Relancez: ./install.sh"
        exit 1
    fi
done

# llama-server
if [ ! -f "$LLAMA_DIR/build/bin/llama-server" ]; then
    echo "❌ llama-server non trouvé"
    echo "   💡 Relancez: ./install.sh"
    exit 1
fi

echo "✅ Vérifications OK"

# 1. Démarrage TinyLlama (Classification)
echo ""
echo "🦙 Démarrage TinyLlama (Classification)..."
cd "$LLAMA_DIR"
./build/bin/llama-server \
    -m "$MODELS_DIR/tinyllama-1.1b-q4.gguf" \
    -ngl 32 \
    --host 0.0.0.0 \
    --port $CLASSIFICATION_PORT \
    --ctx-size 1024 \
    --threads 4 &

TINYLLAMA_PID=$!
echo "   PID: $TINYLLAMA_PID"

# 2. Démarrage Qwen2 (Résumés)
echo ""
echo "🦙 Démarrage Qwen2 (Résumés)..."
./build/bin/llama-server \
    -m "$MODELS_DIR/qwen2-0.5b-q4.gguf" \
    -ngl 32 \
    --host 0.0.0.0 \
    --port $SUMMARY_PORT \
    --ctx-size 2048 \
    --threads 4 &

QWEN2_PID=$!
echo "   PID: $QWEN2_PID"

cd "$SCRIPT_DIR"

# Attente chargement modèles
echo ""
echo "⏳ Chargement modèles (20s)..."
sleep 20

# Tests connectivité
echo ""
echo "🧪 Tests de connectivité..."

# Test TinyLlama
if curl -s --connect-timeout 5 http://localhost:$CLASSIFICATION_PORT/health &>/dev/null; then
    echo "✅ TinyLlama opérationnel: http://localhost:$CLASSIFICATION_PORT"
else
    echo "❌ TinyLlama non accessible"
fi

# Test Qwen2
if curl -s --connect-timeout 5 http://localhost:$SUMMARY_PORT/health &>/dev/null; then
    echo "✅ Qwen2 opérationnel: http://localhost:$SUMMARY_PORT"
else
    echo "❌ Qwen2 non accessible"
fi

# 3. Service API Python (optionnel)
if [ -f "native_service/app.py" ]; then
    echo ""
    echo "🐍 Démarrage service API Python..."
    cd native_service
    python app.py &
    API_PID=$!
    cd ..

    sleep 5

    if curl -s --connect-timeout 5 http://localhost:$API_PORT/health &>/dev/null; then
        echo "✅ API Python opérationnelle: http://localhost:$API_PORT"
    else
        echo "⚠️ API Python non accessible"
    fi
else
    echo "⚠️ Service API Python manquant (continuez quand même)"
fi

# 4. Node-RED - PORT 18880
if [ -f "$NODERED_DIR/start_nodered.sh" ]; then
    echo ""
    echo "🌐 Démarrage Node-RED sur port $NODERED_PORT..."
    cd "$NODERED_DIR"
    ./start_nodered.sh &
    NODERED_PID=$!
    cd "$SCRIPT_DIR"
    
    sleep 8
    
    if curl -s --connect-timeout 5 http://localhost:$NODERED_PORT &>/dev/null; then
        echo "✅ Node-RED opérationnel: http://localhost:$NODERED_PORT"
    else
        echo "⚠️ Node-RED non accessible"
    fi
else
    echo "⚠️ Node-RED non configuré, ignoré"
fi

# Résumé final
echo ""
echo "🎉 Pipeline RSS+LLM Native v3.1 opérationnel !"
echo "==============================================="
echo ""
echo "🔗 Services actifs:"
echo "   • Node-RED (PRINCIPAL): http://localhost:$NODERED_PORT"
echo "   • API Health:           http://localhost:$API_PORT/health"
echo "   • Classification:       http://localhost:$CLASSIFICATION_PORT"
echo "   • Résumés:             http://localhost:$SUMMARY_PORT"
echo ""
echo "📊 Ressources (estimation):"
echo "   • RAM utilisée:     ~2GB (vs 12GB Docker)"
echo "   • Modèles:          ~1GB (vs 8GB transformers)"
echo "   • Démarrage:        ~25s (vs 60s Docker)"
echo ""
echo "💡 Ctrl+C pour arrêter tous les services"
echo ""

# Monitoring
while true; do
    sleep 60
    
    # Vérifier processus critiques
    if ! ps -p $TINYLLAMA_PID &>/dev/null; then
        echo "⚠️ TinyLlama arrêté inattendu"
    fi
    if ! ps -p $QWEN2_PID &>/dev/null; then
        echo "⚠️ Qwen2 arrêté inattendu"
    fi
done
