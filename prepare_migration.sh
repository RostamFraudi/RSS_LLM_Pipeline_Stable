#!/bin/bash
# Script de préparation finale pour la migration
# Rend tous les scripts exécutables et vérifie la configuration

echo "🔧 Préparation Migration RSS LLM Pipeline Native"
echo "==============================================="

# Se positionner dans le bon répertoire
PROJECT_ROOT="/home/rostam/RSS_LLM_Pipeline_Native"
cd "$PROJECT_ROOT" || {
    echo "❌ Impossible d'accéder à $PROJECT_ROOT"
    exit 1
}

echo "📍 Répertoire: $(pwd)"

# Rendre tous les scripts exécutables
echo "🔧 Configuration permissions..."

SCRIPTS=(
    "run_migration.sh"
    "migrate_to_clean_branch.sh"
    "configure_github_remote.sh"
    "validate_migration.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "  ✅ $script rendu exécutable"
    else
        echo "  ⚠️  $script non trouvé"
    fi
done

# Vérification finale
echo ""
echo "🔍 Vérification finale..."

# Test des permissions
for script in "${SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo "  ✅ $script exécutable"
    else
        echo "  ❌ $script non exécutable"
    fi
done

# Vérification Git
if git rev-parse --git-dir &>/dev/null; then
    echo "  ✅ Repository Git"
    echo "  🌿 Branche: $(git branch --show-current)"
else
    echo "  ❌ Pas un repository Git"
fi

# Affichage des scripts disponibles
echo ""
echo "📋 Scripts de migration disponibles:"
echo ""
echo "🎯 SCRIPT PRINCIPAL:"
echo "  ./run_migration.sh          - Menu interactif complet"
echo ""
echo "🔧 SCRIPTS SPÉCIALISÉS:"
echo "  ./migrate_to_clean_branch.sh - Migration automatique"
echo "  ./configure_github_remote.sh - Configuration GitHub"
echo "  ./validate_migration.sh      - Validation complète"
echo ""
echo "📚 DOCUMENTATION:"
echo "  MIGRATION_GUIDE.md          - Guide détaillé"
echo ""

# Instructions d'utilisation
echo "🚀 DÉMARRAGE RECOMMANDÉ:"
echo "  ./run_migration.sh"
echo ""
echo "📖 Puis choisir l'option 1 (Migration complète)"
echo ""

echo "✅ Préparation terminée !"
echo "🎯 Prêt pour la migration !"
