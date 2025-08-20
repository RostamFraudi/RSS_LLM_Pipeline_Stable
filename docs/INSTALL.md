# 📦 Guide d'Installation - RSS LLM Pipeline Native

## 🎯 Installation Rapide

```bash
# Clone du repository
git clone https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable.git
cd RSS_LLM_Pipeline_Stable

# Installation automatique
./install.sh
```

## 🔧 Prérequis

### Système
- **OS** : Ubuntu 20.04+ ou WSL
- **RAM** : 4GB minimum (8GB recommandé)
- **Stockage** : 3GB libres
- **CPU** : 4 cores recommandé

### Logiciels
- **Python** : 3.8+
- **Git** : 2.25+
- **CMake** : 3.16+
- **Build tools** : gcc, g++

## 📋 Installation Manuelle

### 1. Environnement Python
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Compilation llama.cpp
```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_CUDA=ON  # Si GPU NVIDIA
cmake --build build --config Release -j$(nproc)
```

### 3. Modèles GGUF
```bash
mkdir models
# Télécharger TinyLlama 1.1B Q4 (~700MB)
# Télécharger Qwen2 0.5B Q4 (~350MB)
```

## 🧪 Validation

```bash
# Test complet
./test_pipeline.sh

# Démarrage
./start_pipeline.sh
```

## 🔗 Sources Modèles

### TinyLlama 1.1B Q4
- **Source** : https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF
- **Fichier** : tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
- **Taille** : ~700MB

### Qwen2 0.5B Q4
- **Source** : https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF
- **Fichier** : qwen2-0_5b-instruct-q4_0.gguf
- **Taille** : ~350MB

## 🆘 Dépannage

Voir [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
