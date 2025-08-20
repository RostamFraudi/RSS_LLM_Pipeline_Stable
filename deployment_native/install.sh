#!/bin/bash
# Installation complète RSS LLM Pipeline Native - Version Modernisée
# Compatible Ubuntu/WSL avec compilation CMake moderne

set -e

echo "🚀 Installation RSS LLM Pipeline Native (v2.0 CMake)"
echo "===================================================="

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$PROJECT_ROOT/models"
LLAMA_DIR="$PROJECT_ROOT/llama.cpp"
VENV_DIR="$PROJECT_ROOT/venv"

echo "📁 Répertoire projet: $PROJECT_ROOT"

# Vérifications système
echo "📋 Vérifications système..."

# Python 3.8+
if ! python3 --version &>/dev/null; then
    echo "❌ Python 3.8+ requis"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✅ Python $PYTHON_VERSION détecté"

# CMake (requis pour la nouvelle méthode)
if ! command -v cmake &>/dev/null; then
    echo "📦 Installation CMake..."
    sudo apt update
    sudo apt install -y cmake build-essential git wget curl
else
    CMAKE_VERSION=$(cmake --version | head -n1 | awk '{print $3}')
    echo "✅ CMake $CMAKE_VERSION détecté"
fi

# Git
if ! git --version &>/dev/null; then
    echo "❌ Git requis"
    exit 1
fi

# Build tools
if ! command -v g++ &>/dev/null; then
    echo "📦 Installation build tools..."
    sudo apt install -y build-essential
fi

echo "✅ Système vérifié et prêt"

# Vérifier structure projet
if [ ! -f "$PROJECT_ROOT/config/sources.json" ]; then
    echo "❌ Structure projet non trouvée"
    echo "   Assurez-vous d'être dans le bon répertoire"
    echo "   Structure attendue: config/sources.json"
    exit 1
fi

echo "✅ Structure projet validée"

# ==========================================
# 1. ENVIRONNEMENT PYTHON
# ==========================================
echo ""
echo "🐍 Configuration environnement Python..."

if [ ! -d "$VENV_DIR" ]; then
    echo "   Création environnement virtuel..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
echo "✅ Environnement Python activé"

# Mise à jour pip
pip install --upgrade pip

# Installation dépendances légères
echo "   Installation dépendances Python..."
pip install -r "$PROJECT_ROOT/native_service/requirements.txt"
echo "✅ Dépendances Python installées"

# ==========================================
# 2. LLAMA.CPP - COMPILATION MODERNE
# ==========================================
echo ""
echo "🦙 Configuration llama.cpp (méthode CMake moderne)..."

# Clone ou mise à jour
if [ ! -d "$LLAMA_DIR" ]; then
    echo "   Téléchargement llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
else
    echo "   Mise à jour llama.cpp..."
    cd "$LLAMA_DIR"
    git pull
    cd "$PROJECT_ROOT"
fi

# Détection GPU NVIDIA
GPU_SUPPORT=""
if command -v nvidia-smi &>/dev/null; then
    echo "   🎮 GPU NVIDIA détecté"
    GPU_SUPPORT="-DGGML_CUDA=ON"
    
    # Vérifier CUDA
    if command -v nvcc &>/dev/null; then
        CUDA_VERSION=$(nvcc --version | grep -o 'release [0-9]*\.[0-9]*' | awk '{print $2}')
        echo "   ✅ CUDA $CUDA_VERSION disponible"
    else
        echo "   ⚠️ CUDA non détecté, installation CPU seulement"
        GPU_SUPPORT=""
    fi
else
    echo "   💻 Mode CPU seulement"
fi

# Compilation moderne avec CMake
echo "   🔧 Compilation avec CMake..."
cd "$LLAMA_DIR"

# Configuration build
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release"
if [ -n "$GPU_SUPPORT" ]; then
    CMAKE_ARGS="$CMAKE_ARGS $GPU_SUPPORT"
fi

# Détection nombre de cœurs pour compilation parallèle
CORES=$(nproc)
echo "   📊 Utilisation de $CORES cœurs pour compilation"

# Étape 1: Configuration
echo "   🎯 Configuration CMake..."
cmake -B build $CMAKE_ARGS

# Étape 2: Compilation
echo "   ⚙️ Compilation (peut prendre plusieurs minutes)..."
cmake --build build --config Release -j"$CORES"

# Vérification binaire
if [ -f "build/bin/llama-server" ]; then
    echo "✅ llama-server compilé avec succès"
    # Test rapide
    ./build/bin/llama-server --help &>/dev/null && echo "✅ llama-server fonctionnel"
else
    echo "❌ Erreur compilation llama-server"
    exit 1
fi

cd "$PROJECT_ROOT"

# ==========================================
# 3. TÉLÉCHARGEMENT MODÈLES GGUF
# ==========================================
echo ""
echo "📦 Configuration modèles GGUF..."

mkdir -p "$MODELS_DIR"

# URLs modèles (mises à jour avec sources fiables)
TINYLLAMA_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
QWEN2_URL="https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_0.gguf"

# TinyLlama (Classification)
TINYLLAMA_PATH="$MODELS_DIR/tinyllama-1.1b-q4.gguf"
if [ ! -f "$TINYLLAMA_PATH" ]; then
    echo "   ⬇️ Téléchargement TinyLlama (700MB)..."
    wget -O "$TINYLLAMA_PATH" "$TINYLLAMA_URL" || {
        echo "❌ Échec téléchargement TinyLlama"
        exit 1
    }
else
    echo "   ✅ TinyLlama déjà présent"
fi

# Qwen2 (Résumés)
QWEN2_PATH="$MODELS_DIR/qwen2-0.5b-q4.gguf"
if [ ! -f "$QWEN2_PATH" ]; then
    echo "   ⬇️ Téléchargement Qwen2 (350MB)..."
    wget -O "$QWEN2_PATH" "$QWEN2_URL" || {
        echo "❌ Échec téléchargement Qwen2"
        exit 1
    }
else
    echo "   ✅ Qwen2 déjà présent"
fi

# Vérification modèles
echo "   🔍 Vérification modèles..."
for model in "$TINYLLAMA_PATH" "$QWEN2_PATH"; do
    if [ -f "$model" ]; then
        size=$(du -h "$model" | cut -f1)
        echo "   ✅ $(basename "$model"): $size"
    else
        echo "   ❌ Modèle manquant: $(basename "$model")"
        exit 1
    fi
done

# ==========================================
# 4. NODE-RED (OPTIONNEL) - INSTALLATION LOCALE
# ==========================================
echo ""
echo "🌐 Configuration Node-RED..."

if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js $NODE_VERSION détecté"
    
    # Créer répertoire Node-RED local
    NODERED_DIR="$PROJECT_ROOT/node_red_local"
    mkdir -p "$NODERED_DIR"
    
    # Installation Node-RED locale (évite problèmes permissions)
    if ! command -v node-red &>/dev/null; then
        echo "   📦 Installation Node-RED locale..."
        cd "$NODERED_DIR"
        
        # Initialiser package.json local
        if [ ! -f "package.json" ]; then
            npm init -y --scope=local --name=rss-llm-nodered
        fi
        
        # Installation locale Node-RED + modules (SANS -g)
        npm install node-red node-red-node-feedparser node-red-contrib-fs
        
        # Créer script de lancement
        cat > start_nodered.sh << 'EOF'
#!/bin/bash
# Lancement Node-RED local
cd "$(dirname "$0")"
./node_modules/.bin/node-red --userDir ./data --port 1880
EOF
        chmod +x start_nodered.sh
        
        echo "   ✅ Node-RED installé localement"
        cd "$PROJECT_ROOT"
    else
        NODERED_VERSION=$(node-red --version 2>/dev/null | head -n1 || echo "unknown")
        echo "   ✅ Node-RED $NODERED_VERSION déjà installé"
        
        # Vérifier modules dans installation locale
        if [ -d "$NODERED_DIR" ]; then
            cd "$NODERED_DIR"
            if [ ! -d "node_modules/node-red-node-feedparser" ]; then
                echo "   📦 Installation modules RSS localement..."
                npm install node-red-node-feedparser node-red-contrib-fs
            fi
            cd "$PROJECT_ROOT"
        fi
    fi
    
    echo "✅ Node-RED configuré (installation locale)"
else
    echo "⚠️ Node.js non détecté, Node-RED ignoré"
    echo "   Pour installer: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "                   sudo apt-get install -y nodejs"
fi

# ==========================================
# 5. SCRIPTS DE DÉMARRAGE
# ==========================================
echo ""
echo "🔧 Configuration scripts de démarrage..."

# Script de démarrage principal
cat > "$PROJECT_ROOT/start_pipeline.sh" << 'EOF'
#!/bin/bash
# Script de démarrage RSS LLM Pipeline Native
# Généré automatiquement par install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"
LLAMA_DIR="$SCRIPT_DIR/llama.cpp"
MODELS_DIR="$SCRIPT_DIR/models"

echo "🚀 Démarrage RSS LLM Pipeline Native"
echo "===================================="

# Activation environnement
if [ -f "$VENV_DIR/bin/activate" ]; then
    source "$VENV_DIR/bin/activate"
    echo "✅ Environnement Python activé"
else
    echo "❌ Environnement Python non trouvé"
    echo "   Relancez: ./install.sh"
    exit 1
fi

# Variables ports
CLASSIFICATION_PORT=8080
SUMMARY_PORT=8081
API_PORT=15000
NODERED_PORT=1880

# Fonction nettoyage
cleanup() {
    echo ""
    echo "🛑 Arrêt des services..."
    pkill -f "llama-server" || true
    pkill -f "python.*app.py" || true
    pkill -f "node-red" || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# Vérification modèles
for model in "tinyllama-1.1b-q4.gguf" "qwen2-0.5b-q4.gguf"; do
    if [ ! -f "$MODELS_DIR/$model" ]; then
        echo "❌ Modèle manquant: $model"
        echo "   Relancez: ./install.sh"
        exit 1
    fi
done

# Vérification llama-server
if [ ! -f "$LLAMA_DIR/build/bin/llama-server" ]; then
    echo "❌ llama-server non trouvé"
    echo "   Relancez: ./install.sh"
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
echo "⏳ Chargement modèles (15-30s)..."
sleep 15

# Tests connectivité
echo ""
echo "🧪 Tests de connectivité..."

# Test TinyLlama
if curl -s http://localhost:$CLASSIFICATION_PORT/health &>/dev/null; then
    echo "✅ TinyLlama opérationnel: http://localhost:$CLASSIFICATION_PORT"
else
    echo "❌ TinyLlama non accessible"
    cleanup
fi

# Test Qwen2
if curl -s http://localhost:$SUMMARY_PORT/health &>/dev/null; then
    echo "✅ Qwen2 opérationnel: http://localhost:$SUMMARY_PORT"
else
    echo "❌ Qwen2 non accessible"
    cleanup
fi

# 3. Service API Python
echo ""
echo "🐍 Démarrage service API Python..."
cd native_service
python app.py &
API_PID=$!
cd ..

sleep 5

# Test API
if curl -s http://localhost:$API_PORT/health &>/dev/null; then
    echo "✅ API Python opérationnelle: http://localhost:$API_PORT"
else
    echo "⚠️ API Python non accessible"
fi

# 4. Node-RED (si disponible)
if command -v node-red &>/dev/null; then
    echo ""
    echo "🌐 Démarrage Node-RED..."
    
    # Vérifier installation locale ou globale
    NODERED_LOCAL="$SCRIPT_DIR/node_red_local"
    if [ -f "$NODERED_LOCAL/start_nodered.sh" ]; then
        # Utiliser installation locale
        echo "   📦 Utilisation Node-RED local..."
        cd "$NODERED_LOCAL"
        ./start_nodered.sh &
        NODERED_PID=$!
        cd "$SCRIPT_DIR"
    else
        # Utiliser installation globale
        echo "   🌐 Utilisation Node-RED global..."
        mkdir -p node_red_data
        node-red --userDir ./node_red_data --port $NODERED_PORT &
        NODERED_PID=$!
    fi
    
    sleep 5
    
    if curl -s http://localhost:$NODERED_PORT &>/dev/null; then
        echo "✅ Node-RED opérationnel: http://localhost:$NODERED_PORT"
    else
        echo "⚠️ Node-RED non accessible"
    fi
else
    echo "⚠️ Node-RED non installé, ignoré"
fi

# Résumé final
echo ""
echo "🎉 Pipeline RSS+LLM Native opérationnel !"
echo "========================================="
echo ""
echo "🔗 Services actifs:"
echo "   • API Health:       http://localhost:$API_PORT/health"
echo "   • Classification:    http://localhost:$CLASSIFICATION_PORT"
echo "   • Résumés:          http://localhost:$SUMMARY_PORT"
if command -v node-red &>/dev/null; then
echo "   • Node-RED:         http://localhost:$NODERED_PORT"
fi
echo ""
echo "📊 Ressources (estimation):"
echo "   • RAM utilisée:     ~2GB (vs 12GB Docker)"
echo "   • Modèles:          ~1GB (vs 8GB transformers)"
echo "   • Démarrage:        ~20s (vs 60s Docker)"
echo ""
echo "💡 Ctrl+C pour arrêter tous les services"
echo ""

# Monitoring simple
while true; do
    sleep 30
    # Vérifier que les processus sont toujours actifs
    if ! ps -p $TINYLLAMA_PID &>/dev/null; then
        echo "⚠️ TinyLlama arrêté inattendu"
    fi
    if ! ps -p $QWEN2_PID &>/dev/null; then
        echo "⚠️ Qwen2 arrêté inattendu"
    fi
done
EOF

chmod +x "$PROJECT_ROOT/start_pipeline.sh"
echo "✅ Script start_pipeline.sh créé"

# Script de test rapide
cat > "$PROJECT_ROOT/test_pipeline.sh" << 'EOF'
#!/bin/bash
# Test rapide du pipeline RSS LLM
# Vérifie que tous les services répondent

echo "🧪 Test Pipeline RSS+LLM Native"
echo "==============================="

# Ports par défaut
CLASSIFICATION_PORT=8080
SUMMARY_PORT=8081
API_PORT=15000

# Tests API llama.cpp
echo "🦙 Test llama-server..."

# TinyLlama
if curl -s http://localhost:$CLASSIFICATION_PORT/health &>/dev/null; then
    echo "✅ TinyLlama: OK"
else
    echo "❌ TinyLlama: ÉCHEC"
fi

# Qwen2
if curl -s http://localhost:$SUMMARY_PORT/health &>/dev/null; then
    echo "✅ Qwen2: OK"
else
    echo "❌ Qwen2: ÉCHEC"
fi

# API Python
echo ""
echo "🐍 Test API Python..."
if curl -s http://localhost:$API_PORT/health &>/dev/null; then
    echo "✅ API Health: OK"
    
    # Test classification
    echo "🧪 Test classification..."
    response=$(curl -s -X POST http://localhost:$API_PORT/generate_metadata \
        -H "Content-Type: application/json" \
        -d '{"title":"Test Classification","content":"Security breach detected in financial system","source":"test"}')
    
    if echo "$response" | grep -q "domain"; then
        echo "✅ Classification: OK"
        echo "   Réponse: $(echo "$response" | jq -r '.domain // "erreur"')"
    else
        echo "❌ Classification: ÉCHEC"
    fi
else
    echo "❌ API Python: ÉCHEC"
fi

echo ""
echo "🎯 Test terminé"
EOF

chmod +x "$PROJECT_ROOT/test_pipeline.sh"
echo "✅ Script test_pipeline.sh créé"

# ==========================================
# 6. TESTS FINAUX
# ==========================================
echo ""
echo "🧪 Tests de validation..."

# Test llama-server
echo "   🦙 Test llama-server..."
cd "$LLAMA_DIR"
if ./build/bin/llama-server --help &>/dev/null; then
    echo "   ✅ llama-server fonctionnel"
else
    echo "   ❌ llama-server défaillant"
    exit 1
fi
cd "$PROJECT_ROOT"

# Test modèles
echo "   📦 Test modèles GGUF..."
for model_path in "$TINYLLAMA_PATH" "$QWEN2_PATH"; do
    if file "$model_path" | grep -q "data"; then
        echo "   ✅ $(basename "$model_path"): valide"
    else
        echo "   ❌ $(basename "$model_path"): invalide"
        exit 1
    fi
done

# ==========================================
# INSTALLATION TERMINÉE
# ==========================================
echo ""
echo "🎉 Installation RSS LLM Pipeline Native TERMINÉE !"
echo "=================================================="
echo ""
echo "📋 Récapitulatif:"
echo "   • llama.cpp compilé avec CMake moderne"
echo "   • Modèles GGUF téléchargés (1GB total)"
echo "   • Environnement Python configuré"
if command -v node-red &>/dev/null; then
echo "   • Node-RED installé et configuré"
fi
echo ""
echo "🚀 Démarrage:"
echo "   ./start_pipeline.sh"
echo ""
echo "🧪 Test rapide:"
echo "   ./test_pipeline.sh"
echo ""
echo "📊 Espace disque utilisé:"
du -sh "$PROJECT_ROOT" 2>/dev/null | awk '{print "   • Total: " $1}'
du -sh "$MODELS_DIR" 2>/dev/null | awk '{print "   • Modèles: " $1}'
du -sh "$LLAMA_DIR" 2>/dev/null | awk '{print "   • llama.cpp: " $1}'
echo ""
echo "🔗 URLs après démarrage:"
echo "   • API Health:    http://localhost:15000/health"
echo "   • Classification: http://localhost:8080"
echo "   • Résumés:       http://localhost:8081"
if command -v node-red &>/dev/null; then
echo "   • Node-RED:      http://localhost:1880"
fi
echo ""
echo "💡 Logs et debug:"
echo "   • Logs services: journalctl -f | grep llama"
echo "   • Processus:     ps aux | grep -E '(llama|python|node-red)'"
echo "   • Ports:         ss -tlnp | grep -E '(8080|8081|15000|1880)'"
echo ""

# Retour à l'environnement initial
deactivate 2>/dev/null || true

echo "✨ Installation réussie ! Prêt pour le démarrage."