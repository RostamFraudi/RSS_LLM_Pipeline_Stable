#!/bin/bash
# Installation spécifique WSL Windows - Version Modernisée
# Compatible avec WSL 1 et WSL 2 + Windows 10/11

set -e

echo "🪟 Installation RSS LLM Pipeline Native - WSL (v2.0)"
echo "===================================================="

# Variables WSL
WSL_VERSION=$(wsl.exe --version 2>/dev/null | head -n1 || echo "WSL 1")
WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || echo "unknown")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📋 Environnement WSL détecté:"
echo "   • Version: $WSL_VERSION"
echo "   • Utilisateur Windows: $WINDOWS_USER"
echo "   • Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Linux")"

# ==========================================
# OPTIMISATIONS WSL SPÉCIFIQUES
# ==========================================
echo ""
echo "⚙️ Configuration optimisations WSL..."

# Configuration .wslconfig pour WSL 2 (si applicable)
if echo "$WSL_VERSION" | grep -q "WSL version 2" || wsl.exe -l -v 2>/dev/null | grep -q "Version 2"; then
    echo "   🔧 Configuration WSL 2 détectée"
    
    # Créer/mettre à jour .wslconfig dans le home Windows
    WSLCONFIG_PATH="/mnt/c/Users/$WINDOWS_USER/.wslconfig"
    
    if [ "$WINDOWS_USER" != "unknown" ] && [ -d "/mnt/c/Users/$WINDOWS_USER" ]; then
        echo "   📝 Configuration .wslconfig..."
        cat > "$WSLCONFIG_PATH" << EOF
[wsl2]
# Optimisations pour RSS LLM Pipeline
memory=8GB
processors=4
swap=2GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
EOF
        echo "   ✅ .wslconfig configuré: $WSLCONFIG_PATH"
        echo "   💡 Redémarrez WSL après installation: wsl --shutdown"
    else
        echo "   ⚠️ Impossible de configurer .wslconfig automatiquement"
        echo "      Créez manuellement C:\\Users\\%USERNAME%\\.wslconfig"
    fi
fi

# Optimisations système WSL
echo "   🚀 Optimisations performances..."

# Désactiver swap si peu de RAM disponible
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -lt 8 ]; then
    echo "   💾 RAM limitée ($TOTAL_RAM GB), optimisation swap..."
    sudo sysctl vm.swappiness=10
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
fi

# ==========================================
# MISE À JOUR SYSTÈME WSL
# ==========================================
echo ""
echo "📦 Mise à jour système WSL..."

# Mise à jour complète
sudo apt update && sudo apt upgrade -y

# Outils essentiels WSL
echo "   📥 Installation outils WSL..."
sudo apt install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

echo "✅ Système WSL mis à jour"

# ==========================================
# NODE.JS POUR WSL
# ==========================================
echo ""
echo "🌐 Configuration Node.js pour WSL..."

if ! command -v node &>/dev/null; then
    echo "   📥 Installation Node.js LTS..."
    
    # Méthode NodeSource (recommandée)
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Vérification installation
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    echo "   ✅ Node.js $NODE_VERSION installé"
    echo "   ✅ npm $NPM_VERSION installé"
else
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js $NODE_VERSION déjà installé"
fi

# Configuration npm pour WSL
echo "   🔧 Configuration npm..."
npm config set fund false
npm config set audit-level moderate

# ==========================================
# DÉTECTION CUDA/GPU DANS WSL
# ==========================================
echo ""
echo "🎮 Détection support GPU WSL..."

# WSL 2 peut supporter CUDA
if echo "$WSL_VERSION" | grep -q "WSL version 2" || wsl.exe -l -v 2>/dev/null | grep -q "Version 2"; then
    # Vérifier si NVIDIA drivers WSL disponibles
    if command -v nvidia-smi &>/dev/null; then
        echo "   ✅ NVIDIA GPU détecté dans WSL 2"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
        echo "   💡 Support CUDA disponible pour llama.cpp"
    else
        echo "   ⚠️ Pas de GPU NVIDIA détecté"
        echo "      Pour activer: Installez NVIDIA drivers WSL depuis Windows"
        echo "      Guide: https://docs.nvidia.com/cuda/wsl-user-guide/"
    fi
else
    echo "   ℹ️ WSL 1 détecté - Pas de support GPU direct"
    echo "     Considérez la mise à niveau vers WSL 2"
fi

# ==========================================
# CONFIGURATION RÉSEAUX WSL
# ==========================================
echo ""
echo "🌐 Configuration réseau WSL..."

# Test connectivité
if curl -s --connect-timeout 5 https://google.com &>/dev/null; then
    echo "   ✅ Connectivité Internet OK"
else
    echo "   ⚠️ Problème connectivité - Vérifiez proxy/firewall"
fi

# Configuration firewall Windows pour ports
echo "   🔥 Préparation règles firewall Windows..."
echo "      Ports à ouvrir après installation:"
echo "      • 8080 (TinyLlama Classification)"
echo "      • 8081 (Qwen2 Résumés)"
echo "      • 15000 (API Python)"
echo "      • 1880 (Node-RED)"

# ==========================================
# LIENS SYMBOLIQUES WINDOWS
# ==========================================
echo ""
echo "🔗 Configuration accès fichiers Windows..."

# Créer liens vers dossiers Windows courants
WINDOWS_DIRS=(
    "Desktop"
    "Documents"
    "Downloads"
)

mkdir -p ~/windows

for dir in "${WINDOWS_DIRS[@]}"; do
    WINDOWS_PATH="/mnt/c/Users/$WINDOWS_USER/$dir"
    LINK_PATH="~/windows/$dir"
    
    if [ -d "$WINDOWS_PATH" ]; then
        ln -sf "$WINDOWS_PATH" ~/windows/"$dir" 2>/dev/null || true
        echo "   ✅ Lien créé: ~/windows/$dir -> $WINDOWS_PATH"
    fi
done

# ==========================================
# APPEL INSTALLATION PRINCIPALE
# ==========================================
echo ""
echo "🚀 Lancement installation principale..."

# Vérifier présence script principal
if [ -f "$PROJECT_ROOT/install.sh" ]; then
    echo "   📄 Script principal trouvé: $PROJECT_ROOT/install.sh"
    
    # Rendre exécutable
    chmod +x "$PROJECT_ROOT/install.sh"
    
    # Lancer installation
    "$PROJECT_ROOT/install.sh"
else
    echo "   ❌ Script install.sh non trouvé dans $PROJECT_ROOT"
    echo "      Structure attendue:"
    echo "      RSS_LLM_Pipeline_Native/"
    echo "      ├── install.sh"
    echo "      └── scripts/install_wsl.sh (ce script)"
    exit 1
fi

# ==========================================
# POST-INSTALLATION WSL
# ==========================================
echo ""
echo "🔧 Configuration post-installation WSL..."

# Script de démarrage WSL optimisé
cat > "$PROJECT_ROOT/start_wsl.sh" << 'EOF'
#!/bin/bash
# Démarrage optimisé pour WSL
# Auto-généré par install_wsl.sh

echo "🪟 Démarrage RSS LLM Pipeline - WSL"
echo "==================================="

# Variables WSL
WSL_VERSION=$(wsl.exe --version 2>/dev/null | head -n1 || echo "WSL 1")
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')

echo "📊 Environnement WSL:"
echo "   • Version: $WSL_VERSION"
echo "   • RAM disponible: ${TOTAL_RAM}GB"
echo "   • CPU: $(nproc) cœurs"

# Optimisations mémoire WSL
echo "🚀 Optimisations WSL..."
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
echo "   ✅ Cache mémoire nettoyé"

# Vérification GPU si WSL 2
if echo "$WSL_VERSION" | grep -q "WSL version 2"; then
    if command -v nvidia-smi &>/dev/null; then
        echo "   🎮 GPU NVIDIA disponible"
        nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits
    fi
fi

echo ""
echo "🚀 Lancement pipeline principal..."

# Appel script principal
./start_pipeline.sh

echo ""
echo "💡 URLs accessibles depuis Windows:"
echo "   • API Health:    http://localhost:15000/health"
echo "   • Classification: http://localhost:8080"
echo "   • Résumés:       http://localhost:8081"
echo "   • Node-RED:      http://localhost:1880"
EOF

chmod +x "$PROJECT_ROOT/start_wsl.sh"
echo "✅ Script start_wsl.sh créé"

# Guide configuration Windows
cat > "$PROJECT_ROOT/GUIDE_WSL.md" << 'EOF'
# 🪟 Guide Configuration WSL - RSS LLM Pipeline

## Configuration Windows

### 1. Firewall Windows
Ouvrir PowerShell en administrateur et exécuter :

```powershell
# Autoriser ports pipeline LLM
New-NetFirewallRule -DisplayName "RSS LLM - Classification" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
New-NetFirewallRule -DisplayName "RSS LLM - Résumés" -Direction Inbound -Protocol TCP -LocalPort 8081 -Action Allow
New-NetFirewallRule -DisplayName "RSS LLM - API" -Direction Inbound -Protocol TCP -LocalPort 15000 -Action Allow
New-NetFirewallRule -DisplayName "RSS LLM - Node-RED" -Direction Inbound -Protocol TCP -LocalPort 1880 -Action Allow
```

### 2. Optimisation WSL 2 (.wslconfig)
Fichier: `C:\Users\%USERNAME%\.wslconfig`

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
```

Après modification : `wsl --shutdown` puis relancer WSL

### 3. Support GPU NVIDIA (WSL 2)
1. Installer NVIDIA drivers WSL : https://developer.nvidia.com/cuda/wsl
2. Redémarrer Windows
3. Vérifier dans WSL : `nvidia-smi`

## Utilisation

### Démarrage
```bash
./start_wsl.sh
```

### Accès depuis Windows
- Navigateur : http://localhost:PORT
- Fichiers WSL : \\wsl$\Ubuntu\home\username\RSS_LLM_Pipeline_Native
- CMD/PowerShell : `wsl -d Ubuntu`

### Monitoring
```powershell
# Ressources WSL
wsl --list --verbose
wsl --status

# Processus
wsl -e ps aux | grep -E "(llama|python|node-red)"
```

## Troubleshooting

### Problème : Ports non accessibles
```powershell
# Vérifier firewall
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*RSS LLM*"}

# Reset réseau WSL
wsl --shutdown
netsh int ip reset
netsh winsock reset
```

### Problème : Performances lentes
1. Vérifier .wslconfig
2. Augmenter RAM allouée
3. Placer projet sur système de fichiers Linux (pas /mnt/c/)

### Problème : GPU non détecté
1. Vérifier drivers NVIDIA WSL
2. WSL 2 requis pour CUDA
3. Redémarrer Windows après installation drivers
EOF

echo "✅ Guide WSL créé: GUIDE_WSL.md"

# ==========================================
# FINALISATION
# ==========================================
echo ""
echo "🎉 Installation WSL terminée avec succès !"
echo "=========================================="
echo ""
echo "📋 Configuration WSL:"
echo "   • Version: $WSL_VERSION"
echo "   • RAM disponible: ${TOTAL_RAM}GB"
echo "   • Node.js: $(node --version 2>/dev/null || echo "Non installé")"
echo "   • GPU: $(nvidia-smi --query-gpu=count --format=csv,noheader 2>/dev/null || echo "Aucun")"
echo ""
echo "🚀 Démarrage WSL optimisé:"
echo "   ./start_wsl.sh"
echo ""
echo "📚 Documentation:"
echo "   • Guide WSL: ./GUIDE_WSL.md"
echo "   • Configuration: .wslconfig créé automatiquement"
echo ""
echo "🔗 Accès depuis Windows:"
echo "   • Services: http://localhost:PORT"
echo "   • Fichiers: \\\\wsl$\\Ubuntu\\home\\$(whoami)\\RSS_LLM_Pipeline_Native"
echo ""
echo "💡 Optimisations post-installation:"
echo "   1. Redémarrer WSL: wsl --shutdown"
echo "   2. Configurer firewall Windows (voir GUIDE_WSL.md)"
echo "   3. Placer projet sur /home (pas /mnt/c) pour performances"
echo ""

# Suggestion redémarrage WSL
echo "⚠️ IMPORTANT: Redémarrez WSL pour appliquer optimisations:"
echo "   • Depuis Windows: wsl --shutdown"
echo "   • Puis: wsl -d Ubuntu"
echo ""

echo "✨ WSL configuré et optimisé pour RSS LLM Pipeline !"