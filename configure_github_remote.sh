#!/bin/bash
# Configuration remote GitHub pour nouvelle branche
set -e

echo "🔗 Configuration remote GitHub"
echo "=============================="

REPO_URL="https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable.git"
BRANCH="native_clean"

echo "📍 Repository: $REPO_URL"
echo "🌿 Branche: $BRANCH"

# Vérifier état
if ! git rev-parse --verify "$BRANCH" &>/dev/null; then
    echo "❌ Branche $BRANCH non trouvée"
    echo "   Lancez d'abord: ./migrate_to_clean_branch.sh"
    exit 1
fi

# Basculer sur la branche propre
git checkout "$BRANCH"

# Configurer remote
echo "🔧 Configuration remote..."
if git remote get-url origin &>/dev/null; then
    echo "  📝 Mise à jour remote existant"
    git remote set-url origin "$REPO_URL"
else
    echo "  ➕ Ajout nouveau remote"
    git remote add origin "$REPO_URL"
fi

# Vérifier
echo "✅ Remote configuré:"
git remote -v

# Push initial
echo ""
echo "🚀 Push initial vers GitHub..."
read -p "Continuer avec le push ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push -u origin "$BRANCH"
    echo "✅ Push réussi !"
else
    echo "ℹ️  Push annulé. Lancez manuellement: git push -u origin $BRANCH"
fi

echo ""
echo "🎉 Configuration GitHub terminée !"
echo ""
echo "🔗 Repository accessible:"
echo "   $REPO_URL"
echo ""
echo "📋 Commandes utiles:"
echo "   git status           # État de la branche"
echo "   git log --oneline    # Historique commits"
echo "   git push             # Push futurs commits"
