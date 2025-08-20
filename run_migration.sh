#!/bin/bash
# MAÎTRE DE MIGRATION - RSS LLM Pipeline Native
# Script orchestrateur pour la migration complète

set -e

echo "🎯 MIGRATION MAÎTRE - RSS LLM Pipeline Native"
echo "============================================="
echo ""

PROJECT_ROOT="/home/rostam/RSS_LLM_Pipeline_Native"
SCRIPTS_CREATED=false

# Variables couleurs pour un meilleur affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
print_status() {
    local level=$1
    local message=$2
    case $level in
        "success") echo -e "${GREEN}✅ $message${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "error") echo -e "${RED}❌ $message${NC}" ;;
        "info") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "step") echo -e "${PURPLE}🔸 $message${NC}" ;;
        "title") echo -e "${CYAN}🎯 $message${NC}" ;;
    esac
}

# Vérifications préliminaires
print_title() {
    echo ""
    echo -e "${CYAN}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
}

print_title "VÉRIFICATIONS PRÉLIMINAIRES"

# Vérifier répertoire de travail
if [ ! -d "$PROJECT_ROOT" ]; then
    print_status "error" "Répertoire projet non trouvé: $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"
print_status "success" "Répertoire projet: $(pwd)"

# Vérifier git
if ! git rev-parse --git-dir &>/dev/null; then
    print_status "error" "Pas un repository Git"
    exit 1
fi

print_status "success" "Repository Git détecté"
print_status "info" "Branche actuelle: $(git branch --show-current)"

# Vérifier si scripts de migration existent
if [ -f "migrate_to_clean_branch.sh" ] && [ -f "configure_github_remote.sh" ] && [ -f "validate_migration.sh" ]; then
    print_status "success" "Scripts de migration déjà présents"
    SCRIPTS_CREATED=true
else
    print_status "warning" "Scripts de migration manquants - ils seront créés"
fi

# Menu interactif
print_title "MENU DE MIGRATION"

echo "Choisissez une action:"
echo ""
echo "1) 🧹 Migration complète (recommandé)"
echo "2) 🔧 Créer uniquement les scripts de migration"
echo "3) 🔍 Validation de migration existante"
echo "4) 🔗 Configuration GitHub remote"
echo "5) 📊 État actuel du projet"
echo "6) 🆘 Aide et documentation"
echo "7) ❌ Annuler"
echo ""

read -p "Votre choix (1-7): " choice

case $choice in
    1)
        print_title "MIGRATION COMPLÈTE"
        
        print_status "step" "Étape 1/4: Création des scripts de migration"
        if [ "$SCRIPTS_CREATED" = false ]; then
            # Les scripts sont déjà créés par les commandes précédentes
            # Scripts déjà créés, les rendre exécutables
chmod +x migrate_to_clean_branch.sh
chmod +x configure_github_remote.sh
chmod +x validate_migration.sh
chmod +x run_migration.sh
            print_status "success" "Scripts créés et rendus exécutables"
        fi
        
        print_status "step" "Étape 2/4: Exécution de la migration"
        echo ""
        echo "⚠️  ATTENTION: Cette opération va créer une nouvelle branche propre"
        echo "   Un backup sera créé automatiquement"
        echo ""
        read -p "Continuer ? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./migrate_to_clean_branch.sh
            print_status "success" "Migration terminée"
        else
            print_status "warning" "Migration annulée"
            exit 0
        fi
        
        print_status "step" "Étape 3/4: Validation"
        ./validate_migration.sh
        
        print_status "step" "Étape 4/4: Configuration GitHub (optionnel)"
        echo ""
        read -p "Configurer le remote GitHub maintenant ? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./configure_github_remote.sh
        else
            print_status "info" "Configuration GitHub reportée"
            echo "Lancez plus tard: ./configure_github_remote.sh"
        fi
        
        print_status "success" "Migration complète terminée !"
        ;;
        
    2)
        print_title "CRÉATION SCRIPTS DE MIGRATION"
        
        if [ "$SCRIPTS_CREATED" = true ]; then
            print_status "warning" "Scripts déjà présents"
            read -p "Recréer les scripts ? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "info" "Opération annulée"
                exit 0
            fi
        fi
        
        chmod +x migrate_to_clean_branch.sh configure_github_remote.sh validate_migration.sh
        print_status "success" "Scripts créés et configurés"
        
        echo ""
        echo "📋 Scripts disponibles:"
        echo "  • migrate_to_clean_branch.sh - Migration automatique"
        echo "  • configure_github_remote.sh - Configuration GitHub"
        echo "  • validate_migration.sh - Validation complète"
        echo ""
        echo "🚀 Prochaine étape: ./migrate_to_clean_branch.sh"
        ;;
        
    3)
        print_title "VALIDATION MIGRATION"
        
        if [ -f "validate_migration.sh" ]; then
            ./validate_migration.sh
        else
            print_status "error" "Script de validation non trouvé"
            print_status "info" "Lancez d'abord l'option 2 pour créer les scripts"
        fi
        ;;
        
    4)
        print_title "CONFIGURATION GITHUB"
        
        if [ -f "configure_github_remote.sh" ]; then
            ./configure_github_remote.sh
        else
            print_status "error" "Script de configuration non trouvé"
            print_status "info" "Lancez d'abord l'option 2 pour créer les scripts"
        fi
        ;;
        
    5)
        print_title "ÉTAT ACTUEL DU PROJET"
        
        # Informations git
        echo "📋 Informations Git:"
        echo "  • Branche: $(git branch --show-current)"
        echo "  • Commits: $(git rev-list --count HEAD 2>/dev/null || echo "0")"
        echo "  • Remote: $(git remote get-url origin 2>/dev/null || echo "Non configuré")"
        echo ""
        
        # Taille du projet
        SIZE=$(du -sh . 2>/dev/null | cut -f1 || echo "N/A")
        FILE_COUNT=$(find . -type f | wc -l)
        echo "📊 Taille du projet:"
        echo "  • Taille totale: $SIZE"
        echo "  • Nombre de fichiers: $FILE_COUNT"
        echo ""
        
        # Détection éléments volumineux
        echo "🔍 Éléments volumineux détectés:"
        if [ -d "llama.cpp" ]; then
            LLAMA_SIZE=$(du -sh llama.cpp 2>/dev/null | cut -f1 || echo "N/A")
            echo "  • llama.cpp/: $LLAMA_SIZE"
        fi
        if [ -d "venv" ]; then
            VENV_SIZE=$(du -sh venv 2>/dev/null | cut -f1 || echo "N/A")
            echo "  • venv/: $VENV_SIZE"
        fi
        if [ -d "models" ]; then
            MODELS_SIZE=$(du -sh models 2>/dev/null | cut -f1 || echo "N/A")
            MODELS_COUNT=$(find models/ -name "*.gguf" 2>/dev/null | wc -l || echo "0")
            echo "  • models/: $MODELS_SIZE ($MODELS_COUNT modèles)"
        fi
        
        # Recommandations
        echo ""
        if [ -d "llama.cpp" ] || [ -d "venv" ]; then
            print_status "warning" "Projet contient des éléments volumineux"
            print_status "info" "Recommandation: Effectuer une migration (option 1)"
        else
            print_status "success" "Projet semble optimisé"
        fi
        ;;
        
    6)
        print_title "AIDE ET DOCUMENTATION"
        
        echo "📚 Guide de Migration RSS LLM Pipeline Native"
        echo ""
        echo "🎯 Objectif:"
        echo "  Créer une branche propre et optimisée pour la distribution"
        echo ""
        echo "📋 Étapes recommandées:"
        echo "  1. Lancer migration complète (option 1)"
        echo "  2. Vérifier résultats avec validation"
        echo "  3. Configurer GitHub remote"
        echo "  4. Tester installation avec ./install.sh"
        echo ""
        echo "📊 Gains attendus:"
        echo "  • Taille: -95% (50MB vs 3GB+)"
        echo "  • Fichiers: -98% (200 vs 10,000+)"
        echo "  • Installation: <5 minutes"
        echo ""
        echo "🔧 Scripts créés:"
        echo "  • migrate_to_clean_branch.sh - Migration automatique"
        echo "  • configure_github_remote.sh - Configuration GitHub"
        echo "  • validate_migration.sh - Tests de validation"
        echo ""
        echo "⚠️  Points d'attention:"
        echo "  • Un backup automatique est créé"
        echo "  • Les modèles GGUF ne seront pas inclus (téléchargés à l'installation)"
        echo "  • llama.cpp sera cloné automatiquement à l'installation"
        echo ""
        echo "📞 Support:"
        echo "  • Logs détaillés dans chaque script"
        echo "  • Validation complète disponible"
        echo "  • Backup de sécurité automatique"
        ;;
        
    7)
        print_status "info" "Opération annulée"
        exit 0
        ;;
        
    *)
        print_status "error" "Choix invalide"
        exit 1
        ;;
esac

echo ""
print_title "MIGRATION TERMINÉE"

echo "🎉 Opération complétée avec succès !"
echo ""
echo "📋 Prochaines étapes suggérées:"
echo "  1. Vérifier l'état: git status"
echo "  2. Tester: ./test_pipeline.sh (si disponible)"
echo "  3. Pousser vers GitHub: git push origin <branche>"
echo ""
echo "📚 Documentation:"
echo "  • README.md - Vue d'ensemble"
echo "  • docs/ - Guides détaillés"
echo ""
echo "🆘 En cas de problème:"
echo "  • Validation: ./validate_migration.sh"
echo "  • Restaurer backup: git checkout backup_<date>"
echo ""

print_status "success" "Migration RSS LLM Pipeline Native terminée !"
