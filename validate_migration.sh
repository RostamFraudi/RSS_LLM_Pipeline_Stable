#!/bin/bash
# Validation complète de la migration
set -e

echo "🔍 Validation Migration RSS LLM Pipeline"
echo "========================================"

ERRORS=0

# Test 1: Structure requise
echo "📁 Test structure..."
REQUIRED_FILES=(
    "README.md"
    "install.sh" 
    "start_pipeline.sh"
    "test_pipeline.sh"
    ".gitignore"
    "requirements.txt"
    "config/sources.json"
    "native_service/app.py"
    "docs/INSTALL.md"
    "scripts/monitoring.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file MANQUANT"
        ((ERRORS++))
    fi
done

# Test 2: Fichiers exclus
echo ""
echo "🚫 Test exclusions..."
EXCLUDED_PATTERNS=(
    "llama.cpp/"
    "venv/"
    "models/*.gguf"
    "build/"
    "__pycache__/"
    "deployment_native/"
)

for pattern in "${EXCLUDED_PATTERNS[@]}"; do
    if ls $pattern 2>/dev/null | head -1 &>/dev/null; then
        echo "  ⚠️  $pattern présent (normal si créé après migration)"
    else
        echo "  ✅ $pattern exclu"
    fi
done

# Test 3: Taille repository
echo ""
echo "📏 Test taille..."
SIZE=$(du -sh . 2>/dev/null | cut -f1 || echo "N/A")
echo "  📊 Taille totale: $SIZE"

SIZE_MB=$(du -sm . 2>/dev/null | cut -f1 || echo "0")
if [ "$SIZE_MB" -lt 100 ]; then
    echo "  ✅ Taille optimale (<100MB)"
elif [ "$SIZE_MB" -lt 500 ]; then
    echo "  ⚠️  Taille acceptable (${SIZE_MB}MB)"
else
    echo "  ❌ Taille trop importante (${SIZE_MB}MB)"
    ((ERRORS++))
fi

# Test 4: Scripts exécutables
echo ""
echo "🔧 Test permissions..."
EXECUTABLE_FILES=(
    "install.sh"
    "start_pipeline.sh" 
    "test_pipeline.sh"
    "scripts/monitoring.sh"
)

for file in "${EXECUTABLE_FILES[@]}"; do
    if [ -x "$file" ]; then
        echo "  ✅ $file exécutable"
    elif [ -f "$file" ]; then
        echo "  ⚠️  $file non exécutable"
        chmod +x "$file"
        echo "    🔧 Permission corrigée"
    else
        echo "  ❌ $file manquant"
        ((ERRORS++))
    fi
done

# Test 5: Git status
echo ""
echo "📋 Test Git..."
if git rev-parse --git-dir &>/dev/null; then
    echo "  ✅ Repository Git"
    echo "  🌿 Branche: $(git branch --show-current)"
    echo "  📊 Commits: $(git rev-list --count HEAD 2>/dev/null || echo "0")"
    
    # Vérifier fichiers non trackés
    UNTRACKED=$(git ls-files --others --exclude-standard | wc -l)
    if [ "$UNTRACKED" -eq 0 ]; then
        echo "  ✅ Tous fichiers trackés"
    else
        echo "  ⚠️  $UNTRACKED fichiers non trackés"
        git ls-files --others --exclude-standard | head -5
    fi
    
    # Vérifier remote
    if git remote get-url origin &>/dev/null; then
        echo "  ✅ Remote configuré: $(git remote get-url origin)"
    else
        echo "  ⚠️  Remote non configuré"
    fi
else
    echo "  ❌ Pas un repository Git"
    ((ERRORS++))
fi

# Test 6: Structure spécifique
echo ""
echo "🏗️  Test structure spécifique..."

# Vérifier config
if [ -f "config/sources.json" ]; then
    if python3 -c "import json; json.load(open('config/sources.json'))" 2>/dev/null; then
        echo "  ✅ config/sources.json valide"
    else
        echo "  ❌ config/sources.json invalide"
        ((ERRORS++))
    fi
fi

# Vérifier native_service
if [ -f "native_service/app.py" ]; then
    if grep -q "flask" "native_service/app.py"; then
        echo "  ✅ native_service/app.py contient Flask"
    else
        echo "  ⚠️  native_service/app.py sans Flask détecté"
    fi
fi

# Vérifier documentation
DOC_FILES=("docs/INSTALL.md" "docs/TROUBLESHOOTING.md" "docs/CONFIGURATION.md")
DOC_COUNT=0
for doc in "${DOC_FILES[@]}"; do
    [ -f "$doc" ] && ((DOC_COUNT++))
done
echo "  📚 Documentation: $DOC_COUNT/3 fichiers"

# Test 7: Contenu README
echo ""
echo "📖 Test README..."
if [ -f "README.md" ]; then
    if grep -q "RSS LLM Pipeline Native" "README.md"; then
        echo "  ✅ README.md avec titre correct"
    else
        echo "  ⚠️  README.md titre à vérifier"
    fi
    
    if grep -q "install.sh" "README.md"; then
        echo "  ✅ README.md mentionne install.sh"
    else
        echo "  ⚠️  README.md ne mentionne pas install.sh"
    fi
else
    echo "  ❌ README.md manquant"
    ((ERRORS++))
fi

# Résultats finaux
echo ""
echo "📊 Résultats Validation"
echo "======================"

# Statistiques
echo "📈 Statistiques:"
FILE_COUNT=$(git ls-files 2>/dev/null | wc -l || find . -type f | wc -l)
echo "  📁 Fichiers total: $FILE_COUNT"
echo "  📦 Taille: $SIZE"
echo "  🌿 Branche: $(git branch --show-current 2>/dev/null || echo "N/A")"

if [ "$ERRORS" -eq 0 ]; then
    echo ""
    echo "🎉 SUCCÈS - Migration validée !"
    echo ""
    echo "✅ Tous les tests passent"
    echo "📦 Repository optimisé: $SIZE"
    echo "🚀 Prêt pour déploiement"
    echo ""
    echo "🔗 Prochaines étapes:"
    echo "   1. ./test_pipeline.sh           # Tests fonctionnels"
    echo "   2. git push origin $(git branch --show-current 2>/dev/null || echo "BRANCH")  # Push vers GitHub"
    echo "   3. ./install.sh                 # Test installation"
    echo "   4. ./start_pipeline.sh          # Test démarrage"
    echo ""
    echo "📚 Documentation disponible:"
    echo "   • README.md - Vue d'ensemble"
    echo "   • docs/INSTALL.md - Guide installation"
    echo "   • docs/CONFIGURATION.md - Configuration"
    echo "   • docs/TROUBLESHOOTING.md - Dépannage"
else
    echo ""
    echo "❌ ÉCHEC - $ERRORS erreurs détectées"
    echo ""
    echo "🔧 Actions requises:"
    echo "   - Corriger les fichiers manquants"
    echo "   - Vérifier les permissions"
    echo "   - Compléter la structure"
    echo "   - Relancer: ./validate_migration.sh"
    echo ""
    echo "💡 Aide:"
    echo "   - Relancer migration: ./migrate_to_clean_branch.sh"
    echo "   - Vérifier structure dans docs/INSTALL.md"
fi

exit $ERRORS
