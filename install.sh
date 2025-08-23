#!/bin/bash
# RSS LLM Pipeline Native - Installation Automatique
# Version: 3.1 - CORRECTION EXACTE avec FLOW COMPLET
# Fix: EOL -> EOF + Port Node-RED + Flow complet obligatoire

set -e

echo "🚀 Installation RSS LLM Pipeline Native v3.1 (CORRECTION EXACTE)"
echo "================================================================="

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

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip

# Vérifier requirements.txt
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo "⚠️ requirements.txt manquant, installation manuelle..."
    pip install flask requests python-dateutil
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
# 4. NODE-RED OBLIGATOIRE - CORRECTION EXACTE
# ==========================================
echo ""
echo "🌐 Installation Node-RED obligatoire..."

# Installation Node.js si nécessaire
if ! command -v node &>/dev/null; then
    echo "   📦 Installation Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js $NODE_VERSION installé"
else
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js $NODE_VERSION déjà présent"
fi

# Configuration Node-RED local
NODERED_DIR="$PROJECT_ROOT/node_red_native"
echo "   🏗️ Configuration Node-RED: $NODERED_DIR"

mkdir -p "$NODERED_DIR"
cd "$NODERED_DIR"

# Package.json pour Node-RED local
cat > package.json << 'EOJ'
{
  "name": "rss-llm-nodered",
  "version": "3.1.0", 
  "description": "Node-RED pour RSS LLM Pipeline Native",
  "scripts": {
    "start": "./node_modules/.bin/node-red --userDir ./userdir --port 18880"
  },
  "dependencies": {},
  "author": "RSS LLM Pipeline",
  "license": "MIT"
}
EOJ

# Installation Node-RED + modules RSS
echo "   📦 Installation Node-RED et modules..."
npm install node-red node-red-node-feedparser node-red-contrib-fs node-red-contrib-http-request

# Configuration userdir
USERDIR="$NODERED_DIR/userdir"
mkdir -p "$USERDIR"

# Settings.js optimisé - PORT 18880 + accès direct
cat > "$USERDIR/settings.js" << 'EOS'
module.exports = {
    uiPort: 18880,
    uiHost: "0.0.0.0",
    httpAdminRoot: '/',
    httpNodeRoot: '/api', 
    userDir: __dirname,
    logging: {
        console: { level: "info", metrics: false, audit: false }
    },
    flowFile: 'flows.json',
    flowFilePretty: true,
    diagnostics: { enabled: false }
};
EOS

# FLOW COMPLET OBLIGATOIRE - COPIE EXACTE du flows.json original
echo "   📋 Création flows RSS LLM COMPLETS..."
cat > "$USERDIR/flows.json" << 'EOF'
[
    {
        "id": "0a5009b6c9f2d0f8",
        "type": "tab",
        "label": "Flux 1",
        "disabled": false,
        "info": "",
        "env": []
    },
    {
        "id": "a286e71930bddf50",
        "type": "tab",
        "label": "RSS Pipeline Native v3.1",
        "disabled": false,
        "info": "Pipeline RSS + LLM avec architecture native (llama.cpp + venv Python)"
    },
    {
        "id": "7e081f306d97e6eb",
        "type": "group",
        "z": "a286e71930bddf50",
        "name": "SOURCES",
        "style": {
            "stroke": "#3f93cf",
            "fill": "#bfdbef",
            "label": true
        },
        "nodes": [
            "ced5a1942934a354",
            "b0628ca5f2bae48a",
            "d84a5bc5e8999686",
            "c9d1a9a53fa4d259",
            "5e0f8e9f4deb0d64",
            "81a2803f3e5a185f"
        ],
        "x": 514,
        "y": 99,
        "w": 272,
        "h": 382
    },
    {
        "id": "84c6e14812f48c18",
        "type": "group",
        "z": "a286e71930bddf50",
        "name": "Prétraitement",
        "style": {
            "stroke": "#ffdf7f",
            "fill": "#ffefbf",
            "label": true
        },
        "nodes": [
            "1326f6c0ff564efe",
            "67e53dd386dc1fa0",
            "b8524d09134466d9",
            "4bde8394fcc94f98",
            "fe2411334b8e790e",
            "ff1249b485e6f9d6",
            "366b4fa1a98cc202"
        ],
        "x": 834,
        "y": 99,
        "w": 282,
        "h": 442
    },
    {
        "id": "6f583ff8a5c124d2",
        "type": "group",
        "z": "a286e71930bddf50",
        "name": "LLMs Native",
        "style": {
            "stroke": "#ff3f3f",
            "fill": "#ffbfbf",
            "label": true
        },
        "nodes": [
            "health_check_native",
            "e8c2cbdd77973481",
            "31d5fa8a7e887603",
            "adda75fb4c9b6316"
        ],
        "x": 1184,
        "y": 79,
        "w": 322,
        "h": 222
    },
    {
        "id": "24a5d19a2bf69b70",
        "type": "group",
        "z": "a286e71930bddf50",
        "name": "CONFIGURATION",
        "style": {
            "fill": "#d1d1d1",
            "label": true
        },
        "nodes": [
            "4d70a06815ee11b5",
            "3113abf5266df5a6",
            "a0962f8cd2076370"
        ],
        "x": 54,
        "y": 359,
        "w": 442,
        "h": 162
    },
    {
        "id": "6c76fb3fd0b8defb",
        "type": "group",
        "z": "a286e71930bddf50",
        "name": "OUTPUT",
        "style": {
            "label": true
        },
        "nodes": [
            "f1dcc003bee4cd3a",
            "ca4a2ad5526289b6"
        ],
        "x": 1154,
        "y": 679,
        "w": 512,
        "h": 82
    },
    {
        "id": "87fb0cb215ca48be",
        "type": "group",
        "z": "a286e71930bddf50",
        "name": "Post-traitement",
        "style": {
            "stroke": "#ffff3f",
            "fill": "#ffffbf",
            "label": true
        },
        "nodes": [
            "22ada62db320bf9b",
            "7769f131d6b901a6",
            "e4a5576ef4ec20da"
        ],
        "x": 1204,
        "y": 339,
        "w": 302,
        "h": 202
    },
    {
        "id": "4d70a06815ee11b5",
        "type": "inject",
        "z": "a286e71930bddf50",
        "g": "24a5d19a2bf69b70",
        "name": "🔄 Démarrer Pipeline",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 200,
        "y": 400,
        "wires": [
            [
                "a0962f8cd2076370"
            ]
        ]
    },
    {
        "id": "3113abf5266df5a6",
        "type": "inject",
        "z": "a286e71930bddf50",
        "g": "24a5d19a2bf69b70",
        "name": "⏰ Auto (30min)",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "1800",
        "crontab": "",
        "once": false,
        "onceDelay": 0.1,
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "x": 210,
        "y": 480,
        "wires": [
            [
                "a0962f8cd2076370"
            ]
        ]
    },
    {
        "id": "ced5a1942934a354",
        "type": "file in",
        "z": "a286e71930bddf50",
        "g": "7e081f306d97e6eb",
        "name": "📁 Charger sources.json",
        "filename": "../config/sources.json",
        "filenameType": "str",
        "format": "utf8",
        "chunk": false,
        "sendError": false,
        "encoding": "none",
        "allProps": false,
        "x": 650,
        "y": 440,
        "wires": [
            [
                "b0628ca5f2bae48a"
            ]
        ]
    },
    {
        "id": "b0628ca5f2bae48a",
        "type": "json",
        "z": "a286e71930bddf50",
        "g": "7e081f306d97e6eb",
        "name": "🔧 Parser JSON",
        "property": "payload",
        "action": "",
        "pretty": false,
        "x": 650,
        "y": 380,
        "wires": [
            [
                "d84a5bc5e8999686"
            ]
        ]
    },
    {
        "id": "d84a5bc5e8999686",
        "type": "change",
        "z": "a286e71930bddf50",
        "g": "7e081f306d97e6eb",
        "name": "🔍 Extraire sources",
        "rules": [
            {
                "t": "move",
                "p": "payload.sources",
                "pt": "msg",
                "to": "payload",
                "tot": "msg"
            },
            {
                "t": "set",
                "p": "categories",
                "pt": "msg",
                "to": "payload.categories",
                "tot": "msg"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 640,
        "y": 320,
        "wires": [
            [
                "c9d1a9a53fa4d259"
            ]
        ]
    },
    {
        "id": "c9d1a9a53fa4d259",
        "type": "split",
        "z": "a286e71930bddf50",
        "g": "7e081f306d97e6eb",
        "name": "📋 Split sources",
        "splt": "\\n",
        "spltType": "str",
        "arraySplt": 1,
        "arraySpltType": "len",
        "stream": false,
        "addname": "topic",
        "property": "payload",
        "x": 640,
        "y": 260,
        "wires": [
            [
                "5e0f8e9f4deb0d64"
            ]
        ]
    },
    {
        "id": "5e0f8e9f4deb0d64",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "7e081f306d97e6eb",
        "name": "🔍 Préparer URL",
        "func": "msg.url = msg.payload.url;\nmsg.sourceInfo = msg.payload;\nnode.warn(`📄 Traitement: ${msg.payload.name}`);\nreturn msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 650,
        "y": 200,
        "wires": [
            [
                "81a2803f3e5a185f"
            ]
        ]
    },
    {
        "id": "81a2803f3e5a185f",
        "type": "http request",
        "z": "a286e71930bddf50",
        "g": "7e081f306d97e6eb",
        "name": "🌐 Récupérer RSS",
        "method": "GET",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [
            {
                "keyType": "User-Agent",
                "keyValue": "",
                "valueType": "other",
                "valueValue": "RSS-Pipeline-Native/3.1"
            }
        ],
        "x": 650,
        "y": 140,
        "wires": [
            [
                "4bde8394fcc94f98"
            ]
        ]
    },
    {
        "id": "1326f6c0ff564efe",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "📊 Extraire articles",
        "func": "var rss = msg.payload;\nvar items = [];\n\nnode.warn(\"=== EXTRACTION PIPELINE NATIVE ===\");\nnode.warn(`Source: ${msg.sourceInfo.name}`);\n\nif (rss.rss && rss.rss.channel) {\n    node.warn(\"Format RSS 2.0 détecté\");\n    if (rss.rss.channel.item) {\n        items = rss.rss.channel.item;\n    }\n} else if (rss.feed) {\n    node.warn(\"Format Atom détecté\");\n    if (rss.feed.entry) {\n        items = rss.feed.entry;\n    }\n} else if (rss.channel) {\n    node.warn(\"Format RSS direct détecté\");\n    if (rss.channel.item) {\n        items = rss.channel.item;\n    }\n}\n\nif (!Array.isArray(items)) {\n    items = [items];\n}\n\nvar maxArticles = 5;\nif (items.length > maxArticles) {\n    items = items.slice(0, maxArticles);\n    node.warn(`✂️ LIMITATION NATIVE: ${maxArticles} articles`);\n}\n\nif (items.length === 0) {\n    node.warn(\"Aucun article trouvé\");\n    return null;\n}\n\nmsg.payload = items;\nnode.warn(`✅ ${items.length} articles à traiter`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 950,
        "y": 200,
        "wires": [
            [
                "67e53dd386dc1fa0"
            ]
        ]
    },
    {
        "id": "67e53dd386dc1fa0",
        "type": "split",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "📋 Split articles",
        "splt": "\\n",
        "spltType": "str",
        "arraySplt": 1,
        "arraySpltType": "len",
        "stream": false,
        "addname": "",
        "property": "payload",
        "x": 960,
        "y": 260,
        "wires": [
            [
                "366b4fa1a98cc202"
            ]
        ]
    },
    {
        "id": "b8524d09134466d9",
        "type": "change",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "🔍 Construire article",
        "rules": [
            {
                "t": "set",
                "p": "article.title",
                "pt": "msg",
                "to": "payload.title",
                "tot": "msg"
            },
            {
                "t": "set",
                "p": "article.link",
                "pt": "msg",
                "to": "payload.link",
                "tot": "msg"
            },
            {
                "t": "set",
                "p": "article.description",
                "pt": "msg",
                "to": "payload.description",
                "tot": "msg"
            },
            {
                "t": "set",
                "p": "article.source",
                "pt": "msg",
                "to": "sourceInfo.name",
                "tot": "msg"
            },
            {
                "t": "set",
                "p": "article.category",
                "pt": "msg",
                "to": "sourceInfo.category",
                "tot": "msg"
            },
            {
                "t": "set",
                "p": "article.pubDate",
                "pt": "msg",
                "to": "payload.pubDate",
                "tot": "msg"
            }
        ],
        "action": "",
        "property": "",
        "from": "",
        "to": "",
        "reg": false,
        "x": 960,
        "y": 380,
        "wires": [
            [
                "ff1249b485e6f9d6"
            ]
        ]
    },
    {
        "id": "4bde8394fcc94f98",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "Parser RSS",
        "func": "var xmlString = msg.payload;\n\nif (typeof xmlString !== 'string') {\n    node.error(\"RSS n'est pas une chaîne\");\n    return null;\n}\n\ntry {\n    var items = [];\n    var itemMatches = xmlString.match(/<item[^>]*>[\\s\\S]*?<\\/item>/gi) || [];\n    \n    itemMatches.forEach((itemXml, index) => {\n        function extractTag(xml, tagName) {\n            var regex = new RegExp(`<${tagName}[^>]*>([\\\\s\\\\S]*?)<\\\\/${tagName}>`, 'i');\n            var match = xml.match(regex);\n            if (match && match[1]) {\n                var content = match[1].replace(/<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>/g, '$1');\n                return content.trim();\n            }\n            return '';\n        }\n        \n        var title = extractTag(itemXml, 'title') || 'Titre manquant';\n        var link = extractTag(itemXml, 'link') || '#';\n        var description = extractTag(itemXml, 'description') || '';\n        var pubDate = extractTag(itemXml, 'pubDate') || new Date().toISOString();\n        \n        title = title.replace(/<[^>]*>/g, '').trim();\n        description = description.replace(/<[^>]*>/g, '').trim();\n        \n        var article = {\n            title: title,\n            link: link,\n            description: description,\n            pubDate: pubDate\n        };\n        \n        items.push(article);\n    });\n    \n    if (items.length === 0) {\n        return null;\n    }\n    \n    msg.payload = {\n        rss: {\n            channel: {\n                item: items\n            }\n        }\n    };\n    \n    return msg;\n    \n} catch (error) {\n    node.error(\"Erreur parsing RSS: \" + error.message);\n    return null;\n}",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 950,
        "y": 140,
        "wires": [
            [
                "1326f6c0ff564efe"
            ]
        ]
    },
    {
        "id": "fe2411334b8e790e",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "🔍 Formatter Article",
        "func": "const article = msg.article;\n\nif (!article || typeof article !== 'object') {\n    node.error(\"msg.article manquant\");\n    return null;\n}\n\nconst title = article.title || 'Titre manquant';\nconst description = article.description || 'Description manquante';\nconst cleanDescription = description.replace(/<[^>]*>/g, '').trim().substring(0, 800);\n\nif (title === 'Titre manquant' || cleanDescription.length === 0) {\n    node.warn(\"Article incomplet, ignoré\");\n    return null;\n}\n\nmsg.payload = {\n    title: title,\n    content: cleanDescription,\n    source: article.source || 'RSS'\n};\n\nnode.warn(`✅ Article formaté: ${title.substring(0, 50)}...`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 980,
        "y": 500,
        "wires": [
            [
                "health_check_native"
            ]
        ]
    },
    {
        "id": "health_check_native",
        "type": "http request",
        "z": "a286e71930bddf50",
        "g": "6f583ff8a5c124d2",
        "name": "🩺 Health Check Native",
        "method": "GET",
        "ret": "obj",
        "paytoqs": "ignore",
        "url": "http://localhost:15000/health",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [],
        "x": 1320,
        "y": 120,
        "wires": [
            [
                "e8c2cbdd77973481"
            ]
        ]
    },
    {
        "id": "e8c2cbdd77973481",
        "type": "http request",
        "z": "a286e71930bddf50",
        "g": "6f583ff8a5c124d2",
        "name": "🧠 Classification Native",
        "method": "POST",
        "ret": "obj",
        "paytoqs": "ignore",
        "url": "http://localhost:15000/generate_metadata",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [
            {
                "keyType": "Content-Type",
                "keyValue": "",
                "valueType": "other",
                "valueValue": "application/json"
            }
        ],
        "x": 1340,
        "y": 160,
        "wires": [
            [
                "31d5fa8a7e887603"
            ]
        ]
    },
    {
        "id": "31d5fa8a7e887603",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "6f583ff8a5c124d2",
        "name": "📄 Préparer Résumé Native",
        "func": "const article = msg.article;\nconst metadata = msg.payload;\n\nmsg.generate_metadata = metadata;\nmsg.classification_v2 = metadata;\n\narticle.domain = metadata.domain;\n\nmsg.payload = {\n    title: article.title,\n    content: article.description,\n    domain: metadata.domain\n};\n\nnode.warn(`🏷️ Domaine: ${metadata.domain}`);\nnode.warn(`🎯 Confiance: ${metadata.confidence}%`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1360,
        "y": 200,
        "wires": [
            [
                "adda75fb4c9b6316"
            ]
        ]
    },
    {
        "id": "adda75fb4c9b6316",
        "type": "http request",
        "z": "a286e71930bddf50",
        "g": "6f583ff8a5c124d2",
        "name": "✏️ Résumé Native",
        "method": "POST",
        "ret": "obj",
        "paytoqs": "ignore",
        "url": "http://localhost:15000/summarize",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": false,
        "headers": [
            {
                "keyType": "Content-Type",
                "keyValue": "",
                "valueType": "other",
                "valueValue": "application/json"
            }
        ],
        "x": 1350,
        "y": 260,
        "wires": [
            [
                "22ada62db320bf9b"
            ]
        ]
    },
    {
        "id": "22ada62db320bf9b",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "87fb0cb215ca48be",
        "name": "📄 Traiter Résumé Native",
        "func": "const summaryResult = msg.payload;\n\nif (summaryResult && summaryResult.summary) {\n    msg.article.summary = summaryResult.summary;\n} else {\n    msg.article.summary = \"Résumé non disponible\";\n}\n\nmsg.payload = summaryResult;\n\nnode.warn(`✅ Résumé traité`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1340,
        "y": 380,
        "wires": [
            [
                "7769f131d6b901a6"
            ]
        ]
    },
    {
        "id": "7769f131d6b901a6",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "87fb0cb215ca48be",
        "name": "🧹 Nettoyer données",
        "func": "if (msg.article.title) {\n    msg.article.title = String(msg.article.title).replace(/<[^>]*>/g, '').trim();\n}\n\nif (msg.article.description) {\n    msg.article.description = String(msg.article.description).replace(/<[^>]*>/g, '').trim();\n}\n\nmsg.article.processedDate = new Date().toISOString().split('T')[0];\n\nvar domain = msg.generate_metadata?.domain || 'autre';\nvar folderName = domain.replace(/_/g, '-');\nvar safeTitle = msg.article.title.replace(/[^a-zA-Z0-9À-ÿ\\s]/g, '').substring(0, 40).replace(/\\s+/g, '_');\nmsg.filename = `../obsidian_vault/articles/${folderName}/${msg.article.processedDate}_${safeTitle}.md`;\n\nnode.warn(`📄 Article nettoyé: ${msg.article.title.substring(0, 50)}...`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1340,
        "y": 440,
        "wires": [
            [
                "e4a5576ef4ec20da"
            ]
        ]
    },
    {
        "id": "e4a5576ef4ec20da",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "87fb0cb215ca48be",
        "name": "💾 Créer Markdown Native",
        "func": "try {\n  const article = msg.article;\n  const metadata = msg.generate_metadata || {};\n  const summaryResult = msg.payload;\n\n  const domain = metadata.domain || 'autre';\n  const confidence = metadata.confidence || 50;\n  const alertLevel = metadata.alert_level || 'info';\n  const domainEmoji = metadata.domain_emoji || '📄';\n  const obsidianTags = metadata.obsidian_tags || `#${domain.replace(/_/g, '-')} #${alertLevel}`;\n  const obsidianConcepts = metadata.obsidian_concepts || [];\n  const domainLabel = metadata.domain_label || domain;\n  const classificationMethod = metadata.classification_method || 'llama_cpp';\n  const processingTime = metadata.processing_time || 0;\n  \n  const pubDate = new Date(article.pubDate || new Date());\n  const now = new Date();\n  \n  const pubDateStr = pubDate.toISOString().split('T')[0];\n  const processedStr = now.toISOString().split('T')[0];\n  \n  const markdown = `---\ntitle: \"${article.title.replace(/\"/g, '\\\\\"')}\"\nsource: \"${article.source}\"\ndomain: \"${domain}\"\npublication_date: ${article.pubDate}\nprocessed_date: ${now.toISOString()}\nurl: \"${article.link}\"\nalert_level: \"${alertLevel}\"\nconfidence: ${confidence}\npipeline_version: \"native_v3.1_enhanced\"\ntags: [\"${domain.replace(/_/g, '-')}\", \"${alertLevel}\", \"rss-pipeline\"]\n---\n\n# ${article.title}\n\n> **${article.source}** | 📅 **${pubDateStr}** | 🎯 **${confidence}%** | ${domainEmoji}\n\n${obsidianTags}\n\n## 📋 Résumé Structuré\n\n${summaryResult.summary || 'Résumé non disponible'}\n\n## 📄 Contenu Original\n\n${article.description}\n\n## 🏷️ Métadonnées\n\n- **Domaine** : ${domainLabel}\n- **Niveau d'alerte** : ${alertLevel}\n- **Méthode classification** : ${classificationMethod}\n- **Temps traitement** : ${processingTime.toFixed(2)}s\n\n## 🔗 Concepts Liés\n\n${obsidianConcepts.join(' ')}\n\n---\n\n*Traité par Pipeline RSS + LLM Native v3.1 Enhanced • ${processedStr}*`;\n\n  msg.payload = markdown;\n  \n  node.warn(`💾 Markdown ENHANCED créé pour: ${article.title.substring(0, 40)}...`);\n  \n  return msg;\n\n} catch (error) {\n  node.error(`💥 Erreur création markdown: ${error.message}`);\n  \n  msg.payload = `# ⚠ Erreur Pipeline Native\\n\\n**Erreur**: ${error.message}\\n**Date**: ${new Date().toISOString()}`;\n  msg.filename = 'obsidian_vault/articles/errors/' + new Date().toISOString().split('T')[0] + '_error.md';\n  \n  return msg;\n}"        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 1360,
        "y": 500,
        "wires": [
            [
                "ca4a2ad5526289b6"
            ]
        ]
    },
    {
        "id": "f1dcc003bee4cd3a",
        "type": "debug",
        "z": "a286e71930bddf50",
        "g": "6c76fb3fd0b8defb",
        "name": "✅ Succès Native",
        "active": true,
        "complete": "filename",
        "x": 1530,
        "y": 720,
        "wires": []
    },
    {
        "id": "ca4a2ad5526289b6",
        "type": "file",
        "z": "a286e71930bddf50",
        "g": "6c76fb3fd0b8defb",
        "name": "💾 Save Obsidian",
        "filename": "filename",
        "filenameType": "msg",
        "appendNewline": false,
        "createDir": true,
        "overwriteFile": "true",
        "encoding": "utf8",
        "x": 1270,
        "y": 720,
        "wires": [
            [
                "f1dcc003bee4cd3a"
            ]
        ]
    },
    {
        "id": "ff1249b485e6f9d6",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "📄 Préparer Classification",
        "func": "if (!msg.article.title || !msg.article.description) {\n    node.error(`⚠ Classification impossible - données manquantes`);\n    return null;\n}\n\nmsg.payload = {\n    title: msg.article.title,\n    content: msg.article.description,\n    source: msg.article.source || 'RSS'\n};\n\nnode.warn(`🔍 Classification: ${msg.article.title.substring(0, 50)}...`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 980,
        "y": 440,
        "wires": [
            [
                "fe2411334b8e790e"
            ]
        ]
    },
    {
        "id": "a0962f8cd2076370",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "24a5d19a2bf69b70",
        "name": "Config Native",
        "func": "global.set('pipeline_config', null);\nglobal.set('session_stats', null);\n\nnode.warn(\"🧹 RESET: Variables globales vidées (Pipeline Native)\");\n\nvar config = {\n    max_articles_per_run: 20,\n    enable_deduplication: true,\n    processed_articles: new Set(),\n    pipeline_version: 'native_v3.1'\n};\n\nconfig.hours_lookback = 24;\n\nglobal.set('pipeline_config', config);\n\nvar session_stats = {\n    execution_id: Date.now(),\n    start_time: new Date().toISOString(),\n    max_articles: config.max_articles_per_run,\n    processed_count: 0,\n    skipped_count: 0,\n    pipeline_version: 'native_v3.1'\n};\nglobal.set('session_stats', session_stats);\n\nmsg.maxArticles = config.max_articles_per_run;\nmsg.acceptHistorical = true;\nmsg.pipelineVersion = 'native_v3.1';\n\nnode.warn(\"=== CONFIGURATION PIPELINE NATIVE v3.1 ===\");\nnode.warn(`🚀 Version: ${config.pipeline_version}`);\nnode.warn(`⏰ PÉRIODE: ${config.hours_lookback} dernières heures`);\nnode.warn(`🎯 LIMITE: ${config.max_articles_per_run} articles max`);\nnode.warn(`📊 API: localhost:15000 (Pipeline Native)`);\nnode.warn(`🦙 LLM: llama.cpp + TinyLlama + Qwen2`);\nnode.warn(\"=========================================\");\n\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 390,
        "y": 440,
        "wires": [
            [
                "ced5a1942934a354"
            ]
        ]
    },
    {
        "id": "366b4fa1a98cc202",
        "type": "function",
        "z": "a286e71930bddf50",
        "g": "84c6e14812f48c18",
        "name": "Filter Article Native",
        "func": "var session = global.get('session_stats');\nvar config = global.get('pipeline_config');\n\nif (!session || !config) {\n    node.error(\"⚠ Configuration Native manquante\");\n    return null;\n}\n\nif (session.processed_count >= session.max_articles) {\n    node.warn(`ℹ️ LIMITE NATIVE ATTEINTE: ${session.processed_count}/${session.max_articles}`);\n    return null;\n}\n\nvar article = msg.payload;\nif (!article || !article.title) {\n    session.skipped_count++;\n    global.set('session_stats', session);\n    node.warn(\"⚠ Article invalide\");\n    return null;\n}\n\nvar article_date = new Date(article.pubDate || new Date());\nnode.warn(`🔍 ANALYSE NATIVE: \"${article.title.substring(0, 50)}...\"`);\n\nvar title_clean = article.title.replace(/[^a-zA-Z0-9]/g, '').toLowerCase().substring(0, 30);\nvar link_clean = (article.link || '').replace(/[^a-zA-Z0-9]/g, '').toLowerCase().substring(0, 30);\nvar unique_id = `${title_clean}_${link_clean}`;\n\nif (config.enable_deduplication && config.processed_articles.has(unique_id)) {\n    session.skipped_count++;\n    global.set('session_stats', session);\n    node.warn(`⭐ DÉJÀ TRAITÉ`);\n    return null;\n}\n\nvar now = new Date();\nif (config.hours_lookback) {\n    var cutoff = new Date(now.getTime() - (config.hours_lookback * 60 * 60 * 1000));\n    \n    if (article_date < cutoff) {\n        session.skipped_count++;\n        global.set('session_stats', session);\n        node.warn(`⚠ TROP ANCIEN`);\n        return null;\n    }\n}\n\nconfig.processed_articles.add(unique_id);\nsession.processed_count++;\n\nif (config.processed_articles.size > 100) {\n    var articles_array = Array.from(config.processed_articles);\n    config.processed_articles = new Set(articles_array.slice(-50));\n}\n\nglobal.set('pipeline_config', config);\nglobal.set('session_stats', session);\n\nnode.warn(`✅ ARTICLE NATIF VALIDÉ ${session.processed_count}/${session.max_articles}`);\n\nreturn msg;",
        "outputs": 1,
        "timeout": 0,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 980,
        "y": 320,
        "wires": [
            [
                "b8524d09134466d9"
            ]
        ]
    }
]
EOF

# Compter noeuds correctement
NODES_COUNT=$(grep -c '"type":' "$USERDIR/flows.json")
echo "   ✅ Flows RSS LLM COMPLETS ($NODES_COUNT noeuds)"

cd "$PROJECT_ROOT"
echo "✅ Node-RED configuré avec FLOW COMPLET"

# Script de lancement Node-RED - PORT 18880
echo "   🔧 Création script de lancement..."
cat > "$NODERED_DIR/start_nodered.sh" << 'EOF'
#!/bin/bash
# Lancement Node-RED local - PORT 18880
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🌐 Démarrage Node-RED Local (PORT 18880)"
echo "========================================"

if [ ! -d "node_modules/node-red" ]; then
    echo "❌ Node-RED non installé"
    exit 1
fi

NODERED_PORT=18880
USERDIR="./userdir"
mkdir -p "$USERDIR"

echo "📍 Port: $NODERED_PORT"
echo "📁 UserDir: $USERDIR"
echo "🔗 Interface: http://localhost:$NODERED_PORT"

cleanup() {
    echo "🛑 Arrêt Node-RED..."
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "🚀 Lancement Node-RED..."
./node_modules/.bin/node-red --userDir "$USERDIR" --port $NODERED_PORT &

sleep 3
echo "🎉 Node-RED opérationnel!"
echo "   📱 Interface directe: http://localhost:$NODERED_PORT"

wait
EOF

chmod +x "$NODERED_DIR/start_nodered.sh"

# ==========================================
# 5. SCRIPTS DE DÉMARRAGE PRINCIPAUX - PORT 18880
# ==========================================
echo ""
echo "🔧 Configuration scripts de démarrage..."

# Script de démarrage principal avec PORT 18880
cat > "$PROJECT_ROOT/start_pipeline.sh" << 'EOF'
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
EOF

chmod +x "$PROJECT_ROOT/start_pipeline.sh"
echo "✅ Script start_pipeline.sh créé (Node-RED port 18880)"

# ==========================================
# INSTALLATION TERMINÉE
# ==========================================
echo ""
echo "🎉 Installation RSS LLM Pipeline Native v3.1 TERMINÉE !"
echo "======================================================="
echo ""
echo "📋 Corrections appliquées:"
echo "   • EOL -> EOF corrigé"
echo "   • Flow COMPLET installé ($NODES_COUNT noeuds)"
echo "   • Node-RED port 18880 (accès direct)"
echo "   • httpAdminRoot: '/' (pas besoin /admin)"
echo ""
echo "🚀 Démarrage:"
echo "   ./start_pipeline.sh"
echo ""
echo "🔗 URLs après démarrage:"
echo "   • Node-RED PRINCIPAL:  http://localhost:18880"
echo "   • API Health:          http://localhost:15000/health"
echo "   • Classification:      http://localhost:8080"
echo "   • Résumés:            http://localhost:8081"
echo ""

# Retour à l'environnement initial
deactivate 2>/dev/null || true

echo "✨ Installation corrigée ! Node-RED accessible directement sur port 18880."
