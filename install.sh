#!/bin/bash
# RSS LLM Pipeline Native - Installation Automatique
# Version: 3.3 - ASYNC + ROBUST VENV + FIXED FLOWS + NODERED NODE24 FIX

set -e

echo "🚀 Installation RSS LLM Pipeline Native v3.3"
echo "=========================================="

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

# ==========================================
# VÉRIFICATIONS SYSTÈME
# ==========================================
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

# ==========================================
# 1. ENVIRONNEMENT PYTHON
# ==========================================
echo ""
echo "🐍 Configuration environnement Python..."

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "   📦 Création/Réparation de l'environnement virtuel..."
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip

# Vérifier requirements.txt
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo "⚠️ requirements.txt manquant, installation par défaut..."
    pip install "flask[async]" httpx gunicorn uvicorn python-dateutil feedparser python-dotenv asgiref
fi

echo "✅ Environnement Python configuré"

# ==========================================
# 2. LLAMA.CPP
# ==========================================
echo ""
echo "🦙 Configuration llama.cpp..."

if [ ! -d "llama.cpp" ]; then
    echo "   📥 Clonage llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp

# Détection GPU
GPU_SUPPORT=""
if command -v nvidia-smi &>/dev/null; then
    echo "   🎮 GPU NVIDIA détecté"
    GPU_SUPPORT="-DGGML_CUDA=ON"
fi

# Compilation optimisée
echo "   🔧 Compilation llama.cpp..."
cmake -B build -DCMAKE_BUILD_TYPE=Release $GPU_SUPPORT
cmake --build build --config Release -j$(nproc)

# Vérification
if [ -f "build/bin/llama-server" ]; then
    echo "   ✅ llama-server compilé avec succès"
else
    echo "   ❌ Échec compilation llama-server"
    exit 1
fi

cd "$PROJECT_ROOT"
echo "✅ llama.cpp configuré"

# ==========================================
# 3. MODÈLES GGUF
# ==========================================
echo ""
echo "📦 Configuration modèles GGUF..."

mkdir -p "$MODELS_DIR"

# URLs modèles validées
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

echo "✅ Modèles GGUF configurés"

# ==========================================
# 4. NODE-RED - FLOW COMPLET CORRIGÉ
# ==========================================
echo ""
echo "🌐 Installation Node-RED..."

# Installation Node.js si nécessaire
if ! command -v node &>/dev/null; then
    echo "   📦 Installation Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "   ✅ Node.js déjà présent"
fi

# Configuration Node-RED local
NODERED_DIR="$PROJECT_ROOT/node_red_native"
mkdir -p "$NODERED_DIR"
cd "$NODERED_DIR"

# Package.json pour Node-RED local
cat > package.json << 'EOJ'
{
  "name": "rss-llm-nodered",
  "version": "3.2.0",
  "scripts": {
    "start": "./node_modules/.bin/node-red --userDir ./userdir --port 18880"
  },
  "dependencies": {
    "node-red": "^3.1.0",
    "node-red-node-feedparser": "^0.3.0",
    "node-red-contrib-fs": "^1.4.1",
    "node-red-contrib-http-request": "^0.1.14"
  }
}
EOJ

# Installation Node-RED + modules
echo "   📦 Installation Node-RED et modules..."
npm install

# PATCH: Node.js 20+ Compatibility (util.log removal)
echo "   🩹 Patching Node-RED for Node.js 20+ compatibility..."
RED_JS="node_modules/node-red/red.js"
LOG_JS="node_modules/@node-red/util/lib/log.js"

if [ -f "$RED_JS" ]; then
    sed -i 's/util.log/console.log/g' "$RED_JS"
    echo "      ✅ $RED_JS patched"
fi

if [ -f "$LOG_JS" ]; then
    sed -i 's/util.log/console.log/g' "$LOG_JS"
    echo "      ✅ $LOG_JS patched"
fi

echo "   📜 Création du script de démarrage Node-RED..."
cat > start_nodered.sh << 'EOS'
#!/bin/bash
./node_modules/.bin/node-red --userDir ./userdir --port 18880
EOS
chmod +x start_nodered.sh

# Configuration userdir
USERDIR="$NODERED_DIR/userdir"
mkdir -p "$USERDIR"

# Settings.js
cat > "$USERDIR/settings.js" << 'EOS'
module.exports = {
    uiPort: 18880,
    uiHost: "0.0.0.0",
    httpAdminRoot: '/',
    httpNodeRoot: '/api', 
    userDir: __dirname,
    flowFile: 'flows.json',
    flowFilePretty: true
};
EOS

# FLOW COMPLET CORRIGÉ (Bypass health check + Fix JSON)
echo "   📋 Création flows RSS LLM..."
cat > "$USERDIR/flows.json" << 'EOF'
[
    {
        "id": "a286e71930bddf50",
        "type": "tab",
        "label": "RSS Pipeline Native v3.2"
    },
    {
        "id": "4d70a06815ee11b5",
        "type": "inject",
        "z": "a286e71930bddf50",
        "name": "🔄 Démarrer Pipeline",
        "props": [{"p": "payload"}],
        "repeat": "",
        "crontab": "",
        "once": false,
        "x": 150,
        "y": 100,
        "wires": [["a0962f8cd2076370"]]
    },
    {
        "id": "a0962f8cd2076370",
        "type": "function",
        "z": "a286e71930bddf50",
        "name": "Config Native",
        "func": "msg.maxArticles = 20;\nreturn msg;",
        "x": 350,
        "y": 100,
        "wires": [["ced5a1942934a354"]]
    },
    {
        "id": "ced5a1942934a354",
        "type": "file in",
        "z": "a286e71930bddf50",
        "name": "📁 Charger sources.json",
        "filename": "../config/sources.json",
        "filenameType": "str",
        "format": "utf8",
        "x": 550,
        "y": 100,
        "wires": [["b0628ca5f2bae48a"]]
    },
    {
        "id": "b0628ca5f2bae48a",
        "type": "json",
        "z": "a286e71930bddf50",
        "name": "Parser JSON",
        "x": 750,
        "y": 100,
        "wires": [["d84a5bc5e8999686"]]
    },
    {
        "id": "d84a5bc5e8999686",
        "type": "change",
        "z": "a286e71930bddf50",
        "name": "Extraire sources",
        "rules": [{"t": "set", "p": "payload", "pt": "msg", "to": "payload.sources", "tot": "msg"}],
        "x": 150,
        "y": 200,
        "wires": [["c9d1a9a53fa4d259"]]
    },
    {
        "id": "c9d1a9a53fa4d259",
        "type": "split",
        "z": "a286e71930bddf50",
        "name": "Split sources",
        "sarray": true,
        "x": 350,
        "y": 200,
        "wires": [["5e0f8e9f4deb0d64"]]
    },
    {
        "id": "5e0f8e9f4deb0d64",
        "type": "function",
        "z": "a286e71930bddf50",
        "name": "Préparer URL",
        "func": "msg.url = msg.payload.url;\nmsg.sourceInfo = msg.payload;\nreturn msg;",
        "x": 550,
        "y": 200,
        "wires": [["81a2803f3e5a185f"]]
    },
    {
        "id": "81a2803f3e5a185f",
        "type": "http request",
        "z": "a286e71930bddf50",
        "name": "Récupérer RSS",
        "method": "GET",
        "ret": "txt",
        "url": "",
        "x": 750,
        "y": 200,
        "wires": [["4bde8394fcc94f98"]]
    },
    {
        "id": "4bde8394fcc94f98",
        "type": "function",
        "z": "a286e71930bddf50",
        "name": "Parser RSS",
        "func": "var xml = msg.payload;\nvar items = [];\nvar matches = xml.match(/<item[\\s\\S]*?<\\/item>/gi) || [];\nmatches.forEach(item => {\n  var title = (item.match(/<title>([\\s\\S]*?)<\\/title>/i) || [])[1] || '';\n  var desc = (item.match(/<description>([\\s\\S]*?)<\\/description>/i) || [])[1] || '';\n  var link = (item.match(/<link>([\\s\\S]*?)<\\/link>/i) || [])[1] || '';\n  items.push({\n    title: title.replace(/<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>/g, '$1').replace(/<[^>]*>/g, '').trim(),\n    description: desc.replace(/<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>/g, '$1').replace(/<[^>]*>/g, '').trim(),\n    link: link.trim(),\n    source: msg.sourceInfo.name,\n    pubDate: (item.match(/<pubDate>([\\s\\S]*?)<\\/pubDate>/i) || [])[1] || new Date().toISOString()\n  });\n});\nmsg.payload = items.slice(0, 5);\nreturn msg;",
        "x": 150,
        "y": 300,
        "wires": [["67e53dd386dc1fa0"]]
    },
    {
        "id": "67e53dd386dc1fa0",
        "type": "split",
        "z": "a286e71930bddf50",
        "name": "Split articles",
        "sarray": true,
        "x": 350,
        "y": 300,
        "wires": [["b8524d09134466d9"]]
    },
    {
        "id": "b8524d09134466d9",
        "type": "change",
        "z": "a286e71930bddf50",
        "name": "Construire article",
        "rules": [{"t": "set", "p": "article", "pt": "msg", "to": "payload", "tot": "msg"}],
        "x": 550,
        "y": 300,
        "wires": [["fe2411334b8e790e"]]
    },
    {
        "id": "fe2411334b8e790e",
        "type": "function",
        "z": "a286e71930bddf50",
        "name": "🔍 Formatter Article",
        "func": "msg.payload = {\n  title: msg.article.title,\n  content: msg.article.description.substring(0, 800),\n  source: msg.article.source\n};\nreturn msg;",
        "x": 750,
        "y": 300,
        "wires": [["e8c2cbdd77973481"]]
    },
    {
        "id": "e8c2cbdd77973481",
        "type": "http request",
        "z": "a286e71930bddf50",
        "name": "🧠 Classification Native",
        "method": "POST",
        "ret": "obj",
        "url": "http://localhost:15000/generate_metadata",
        "x": 150,
        "y": 400,
        "wires": [["31d5fa8a7e887603"]]
    },
    {
        "id": "31d5fa8a7e887603",
        "type": "function",
        "z": "a286e71930bddf50",
        "name": "Préparer Résumé",
        "func": "msg.generate_metadata = msg.payload;\nmsg.payload = {\n  title: msg.article.title,\n  content: msg.article.description,\n  domain: msg.payload.domain\n};\nreturn msg;",
        "x": 350,
        "y": 400,
        "wires": [["adda75fb4c9b6316"]]
    },
    {
        "id": "adda75fb4c9b6316",
        "type": "http request",
        "z": "a286e71930bddf50",
        "name": "✏️ Résumé Native",
        "method": "POST",
        "ret": "obj",
        "url": "http://localhost:15000/summarize",
        "x": 550,
        "y": 400,
        "wires": [["e4a5576ef4ec20da"]]
    },
    {
        "id": "e4a5576ef4ec20da",
        "type": "function",
        "z": "a286e71930bddf50",
        "name": "💾 Créer Markdown",
        "func": "const meta = msg.generate_metadata;\nconst summary = msg.payload.summary;\nconst now = new Date().toISOString();\nmsg.payload = `---\\ntitle: \"${msg.article.title}\"\\ndomain: \"${meta.domain}\"\\n---\\n# ${msg.article.title}\\n\\n## Résumé\\n${summary}\\n\\n## Tags\\n${meta.obsidian_tags}`;\nconst safeTitle = msg.article.title.replace(/[^a-z0-9]/gi, '_').substring(0, 50);\nmsg.filename = `../obsidian_vault/articles/${meta.domain}/${safeTitle}.md`;\nreturn msg;",
        "x": 750,
        "y": 400,
        "wires": [["ca4a2ad5526289b6"]]
    },
    {
        "id": "ca4a2ad5526289b6",
        "type": "file",
        "z": "a286e71930bddf50",
        "name": "💾 Save Obsidian",
        "filename": "filename",
        "filenameType": "msg",
        "appendNewline": true,
        "createDir": true,
        "overwriteFile": "true",
        "x": 150,
        "y": 500,
        "wires": [[]]
    }
]
EOF

cd "$PROJECT_ROOT"
chmod +x start_pipeline.sh
echo "✅ Installation v3.2 terminée !"
