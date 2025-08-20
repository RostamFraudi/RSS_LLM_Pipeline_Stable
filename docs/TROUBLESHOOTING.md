# 🆘 Dépannage - RSS LLM Pipeline Native

## ❌ Problèmes Courants

### Installation Python
**Erreur** : `python3: command not found`
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

### Compilation llama.cpp
**Erreur** : Build échoue
```bash
sudo apt install build-essential cmake
```

### Modèles GGUF
**Erreur** : Modèles non trouvés
```bash
mkdir -p models
# Télécharger manuellement depuis HuggingFace
```

### GPU NVIDIA
**Erreur** : GPU non détecté
```bash
# Vérifier drivers
nvidia-smi
# Recompiler avec CUDA
cd llama.cpp && cmake -B build -DGGML_CUDA=ON
```

## 🔧 Diagnostic

### Logs
```bash
# Processus actifs
ps aux | grep -E "(llama|python)" | grep -v grep

# Ports occupés
ss -tlnp | grep -E "(8080|8081|15000)"
```

### Reset Complet
```bash
# Nettoyage total
pkill -f llama-server
rm -rf venv/ llama.cpp/ models/
./install.sh
```
