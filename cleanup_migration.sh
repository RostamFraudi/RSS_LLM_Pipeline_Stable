#!/bin/bash
# Script de nettoyage post-migration pour optimiser la taille
set -e

echo "🧹 Nettoyage Post-Migration - Optimisation Taille"
echo "================================================="

PROJECT_ROOT="/home/rostam/RSS_LLM_Pipeline_Native"
cd "$PROJECT_ROOT"

echo "📍 Répertoire: $(pwd)"
echo "🌿 Branche: $(git branch --show-current)"

# Vérifier qu'on est sur la bonne branche
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "native_clean" ]; then
    echo "⚠️  Pas sur la branche native_clean"
    echo "   Branche actuelle: $CURRENT_BRANCH"
    read -p "Continuer quand même ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Nettoyage annulé"
        exit 1
    fi
fi

# Afficher taille actuelle
echo ""
echo "📊 Taille avant nettoyage:"
du -sh . 2>/dev/null | cut -f1

# Éléments à supprimer définitivement
CLEANUP_DIRS=(
    "llama.cpp"
    "venv"
    "models"
    "build"
    "deployment_native"
    "node_red_local"
    "node_red_data"
    "node_red_native"
    "logs"
    "tests"
)

CLEANUP_PATTERNS=(
    "__pycache__"
    "*.pyc"
    "*.pyo"
    "*.log"
    ".cache"
    "tmp"
    "temp"
)

echo ""
echo "🗑️  Suppression éléments volumineux..."

# Supprimer les répertoires volumineux
for dir in "${CLEANUP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        size=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "?")
        echo "  🗂️  Suppression $dir ($size)..."
        rm -rf "$dir"
    else
        echo "  ✅ $dir déjà absent"
    fi
done

# Supprimer les patterns de fichiers
for pattern in "${CLEANUP_PATTERNS[@]}"; do
    if find . -name "$pattern" -type f 2>/dev/null | head -1 | grep -q .; then
        echo "  🗂️  Suppression fichiers $pattern..."
        find . -name "$pattern" -type f -delete 2>/dev/null || true
    fi
    if find . -name "$pattern" -type d 2>/dev/null | head -1 | grep -q .; then
        echo "  🗂️  Suppression dossiers $pattern..."
        find . -name "$pattern" -type d -exec rm -rf {} + 2>/dev/null || true
    fi
done

# Nettoyer fichiers temporaires spécifiques
echo ""
echo "🧼 Nettoyage fichiers temporaires..."

# Supprimer logs et temporaires
find . -name "*.log" -delete 2>/dev/null || true
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "Thumbs.db" -delete 2>/dev/null || true

# Nettoyer git
echo "  🔧 Nettoyage Git..."
git gc --aggressive --prune=now 2>/dev/null || true

# Vérifier .gitignore pour inclure les exclusions
echo ""
echo "📝 Mise à jour .gitignore..."

cat >> .gitignore << 'EOF'

# === Ajouts post-migration ===
# Répertoires volumineux (installés automatiquement)
llama.cpp/
venv/
models/
build/
deployment_native/
node_red_local/
node_red_data/
node_red_native/
tests/

# Fichiers temporaires
*.pyc
*.pyo
__pycache__/
*.log
.cache/
tmp/
temp/

# OS et IDE
.DS_Store
Thumbs.db
*.swp
*~
EOF

# Supprimer les doublons dans .gitignore
if [ -f ".gitignore" ]; then
    sort .gitignore | uniq > .gitignore.tmp
    mv .gitignore.tmp .gitignore
fi

echo ""
echo "📦 Taille après nettoyage:"
du -sh . 2>/dev/null | cut -f1

# Commiter les changements
echo ""
echo "💾 Commit des optimisations..."
git add .gitignore
git add -A  # Inclure les suppressions
git commit -m "🧹 Optimisation post-migration - Nettoyage complet

🗑️  Suppression éléments volumineux:
- llama.cpp/ (sera cloné à l'installation)
- venv/ (sera créé à l'installation)  
- models/ (seront téléchargés à l'installation)
- build/ et temporaires
- Anciens scripts deployment_native/

📝 Mise à jour .gitignore pour éviter futurs ajouts

🎯 Objectif: Repository <100MB pour distribution"

# Vérifications finales
echo ""
echo "🔍 Vérifications finales..."

# Taille finale
FINAL_SIZE=$(du -sh . 2>/dev/null | cut -f1)
FINAL_SIZE_MB=$(du -sm . 2>/dev/null | cut -f1)
echo "  📊 Taille finale: $FINAL_SIZE (${FINAL_SIZE_MB}MB)"

# Nombre de fichiers
FILE_COUNT=$(git ls-files | wc -l)
echo "  📁 Fichiers Git: $FILE_COUNT"

# Évaluation
if [ "$FINAL_SIZE_MB" -lt 100 ]; then
    echo "  ✅ Taille optimale (<100MB)"
    RESULT="SUCCESS"
elif [ "$FINAL_SIZE_MB" -lt 500 ]; then
    echo "  ⚠️  Taille acceptable (<500MB)"
    RESULT="ACCEPTABLE"
else
    echo "  ❌ Taille encore trop importante"
    RESULT="NEEDS_MORE_CLEANUP"
fi

echo ""
echo "📋 Résumé Nettoyage:"
echo "==================="
echo "  🎯 Résultat: $RESULT"
echo "  📦 Taille: $FINAL_SIZE"
echo "  📁 Fichiers: $FILE_COUNT"
echo "  🌿 Branche: $(git branch --show-current)"

if [ "$RESULT" = "SUCCESS" ] || [ "$RESULT" = "ACCEPTABLE" ]; then
    echo ""
    echo "🎉 Nettoyage réussi !"
    echo ""
    echo "🚀 Prochaines étapes:"
    echo "  1. Validation: ./validate_migration.sh"
    echo "  2. Configuration GitHub: ./configure_github_remote.sh"
    echo "  3. Test installation: ./install.sh"
else
    echo ""
    echo "⚠️  Nettoyage supplémentaire nécessaire"
    echo ""
    echo "🔍 Analyse des gros fichiers:"
    echo "$(find . -type f -size +10M 2>/dev/null | head -10)"
    echo ""
    echo "🔍 Répertoires volumineux:"
    echo "$(du -sh */ 2>/dev/null | sort -hr | head -10)"
fi

echo ""
echo "✅ Script de nettoyage terminé"
