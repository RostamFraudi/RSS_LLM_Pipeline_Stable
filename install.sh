#!/bin/bash
# RSS LLM Pipeline Native - Installation Automatique
# Version: 3.0 - Consolidée et Optimisée

set -e

echo "🚀 Installation RSS LLM Pipeline Native v3.0"
echo "============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Détection environnement
if grep -q Microsoft /proc/version 2>/dev/null || [[ "$WSL_DISTRO_NAME" ]]; then
    echo "🪟 Environnement WSL détecté"
    export IS_WSL=true
else
    echo "🐧 Environnement Linux natif"
    export IS_WSL=false
fi

# Variables
export PROJECT_ROOT="$SCRIPT_DIR"
export VENV_DIR="$PROJECT_ROOT/venv"
export MODELS_DIR="$PROJECT_ROOT/models"
export LLAMA_DIR="$PROJECT_ROOT/llama.cpp"

echo "📁 Répertoire projet: $PROJECT_ROOT"

# Vérifications système
echo ""
echo "🔍 Vérifications système..."

python3 --version || { echo "❌ Python 3.8+ requis"; exit 1; }
git --version || { echo "❌ Git requis"; exit 1; }

if command -v cmake &>/dev/null; then
    echo "✅ CMake disponible"
else
    echo "📦 Installation CMake..."
    sudo apt update && sudo apt install -y cmake build-essential
fi

# Installation modulaire
echo ""
echo "📦 Installation par modules..."

chmod +x scripts/*.sh 2>/dev/null || true

# 1. Environnement Python
echo "🐍 Configuration environnement Python..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Environnement Python configuré"

# 2. llama.cpp
echo "🦙 Configuration llama.cpp..."
if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
fi
cd llama.cpp

# Détection GPU
GPU_SUPPORT=""
if command -v nvidia-smi &>/dev/null; then
    echo "  🎮 GPU NVIDIA détecté"
    GPU_SUPPORT="-DGGML_CUDA=ON"
fi

cmake -B build -DCMAKE_BUILD_TYPE=Release $GPU_SUPPORT
cmake --build build --config Release -j$(nproc)
cd ..
echo "✅ llama.cpp compilé"

# 3. Modèles
echo "📥 Configuration modèles..."
mkdir -p models
echo "⚠️  Téléchargement modèles GGUF requis:"
echo "   • TinyLlama 1.1B Q4 (~700MB)"
echo "   • Qwen2 0.5B Q4 (~350MB)"
echo ""
echo "🔗 Sources recommandées:"
echo "   • https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
echo "   • https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF"

# 4. Structure Obsidian
echo "📝 Configuration Obsidian..."
mkdir -p obsidian_vault/articles
echo "# Articles générés automatiquement" > obsidian_vault/articles/.gitkeep

echo ""
echo "🎉 Installation terminée !"
echo ""
echo "🚀 Démarrage:"
echo "   ./start_pipeline.sh"
echo ""
echo "🧪 Tests:"
echo "   ./test_pipeline.sh"
echo ""
echo "📚 Documentation:"
echo "   docs/ - Guides détaillés"
echo "   README.md - Vue d'ensemble"
