#!/bin/bash
# Setup llama.cpp pour RSS LLM Pipeline Native

set -e

echo "🦙 Setup llama.cpp..."

# Clone et compilation si nécessaire
if [ ! -d "llama.cpp" ]; then
    echo "📥 Clonage llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp.git
fi

cd llama.cpp

# Compilation
echo "🔨 Compilation llama.cpp..."
make -j$(nproc)

cd ..

echo "✅ llama.cpp configuré"
echo "   Exécutable: llama.cpp/build/bin/llama-server"
