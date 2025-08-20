#!/bin/bash
# RSS LLM Pipeline Native - Tests
echo "🧪 Tests RSS LLM Pipeline Native"
echo "================================"

ERRORS=0

# Tests de base
echo "🔍 Tests de base..."

# Test 1: Structure
echo "  📁 Structure projet..."
[ -f "install.sh" ] && echo "    ✅ install.sh" || { echo "    ❌ install.sh"; ((ERRORS++)); }
[ -f "start_pipeline.sh" ] && echo "    ✅ start_pipeline.sh" || { echo "    ❌ start_pipeline.sh"; ((ERRORS++)); }
[ -d "config" ] && echo "    ✅ config/" || { echo "    ❌ config/"; ((ERRORS++)); }
[ -d "native_service" ] && echo "    ✅ native_service/" || { echo "    ❌ native_service/"; ((ERRORS++)); }

# Test 2: Python
echo "  🐍 Environnement Python..."
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    python -c "import flask, requests" &>/dev/null && echo "    ✅ Dépendances Python" || { echo "    ❌ Dépendances manquantes"; ((ERRORS++)); }
else
    echo "    ❌ venv non trouvé - Lancez ./install.sh"
fi

# Test 3: llama.cpp
echo "  🦙 llama.cpp..."
if [ -f "llama.cpp/build/bin/llama-server" ]; then
    echo "    ✅ llama-server compilé"
else
    echo "    ❌ llama-server non trouvé - Lancez ./install.sh"
fi

# Test 4: Modèles
echo "  📦 Modèles GGUF..."
MODEL_COUNT=$(find models/ -name "*.gguf" 2>/dev/null | wc -l || echo "0")
echo "    📊 $MODEL_COUNT modèles trouvés"

# Test 5: Configuration
echo "  ⚙️ Configuration..."
[ -f "config/sources.json" ] && echo "    ✅ sources.json" || { echo "    ❌ sources.json"; ((ERRORS++)); }

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ Tous les tests passent !"
    echo "🚀 Prêt pour démarrage avec ./start_pipeline.sh"
else
    echo "❌ $ERRORS erreurs détectées"
    echo "🔧 Lancez ./install.sh pour corriger"
fi

exit $ERRORS
