#!/bin/bash
# Script de configuration Git/GitHub pour RSS LLM Pipeline
set -e

echo "🔐 Configuration Git/GitHub - RSS LLM Pipeline"
echo "=============================================="

# Variables
REPO_URL_HTTPS="https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable.git"
REPO_URL_SSH="git@github.com:RostamFraudi/RSS_LLM_Pipeline_Stable.git"

echo ""
echo "Choisissez votre méthode d'authentification:"
echo ""
echo "1) 🔑 Personal Access Token (HTTPS)"
echo "2) 🔐 SSH Key"
echo "3) 📱 GitHub CLI"
echo "4) ℹ️  Aide et diagnostics"
echo "5) ❌ Annuler"
echo ""

read -p "Votre choix (1-5): " choice

case $choice in
    1)
        echo ""
        echo "🔑 Configuration Personal Access Token"
        echo "====================================="
        echo ""
        echo "📋 Étapes:"
        echo "1. Aller sur https://github.com/settings/tokens"
        echo "2. Generate new token (classic)"
        echo "3. Sélectionner les permissions : repo, workflow"
        echo "4. Copier le token généré"
        echo ""
        
        read -p "Avez-vous créé votre token ? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            read -p "Entrez votre username GitHub: " github_username
            
            # Configurer credential helper
            git config --global credential.helper store
            
            # Configurer le remote
            git remote set-url origin "$REPO_URL_HTTPS"
            
            echo ""
            echo "✅ Configuration terminée !"
            echo ""
            echo "🚀 Pour pusher:"
            echo "   git push -u origin native_clean"
            echo ""
            echo "⚠️  Quand demandé:"
            echo "   Username: $github_username"
            echo "   Password: [VOTRE_TOKEN_PAS_VOTRE_MOT_DE_PASSE]"
        else
            echo "❌ Configuration annulée"
            echo "Créez d'abord votre token sur GitHub"
        fi
        ;;
        
    2)
        echo ""
        echo "🔐 Configuration SSH Key"
        echo "======================="
        echo ""
        
        # Vérifier si une clé SSH existe
        if [ -f ~/.ssh/id_ed25519.pub ]; then
            echo "✅ Clé SSH existante trouvée"
            echo ""
            echo "📋 Votre clé publique:"
            cat ~/.ssh/id_ed25519.pub
            echo ""
            echo "📋 Copiez cette clé et ajoutez-la à GitHub:"
            echo "   https://github.com/settings/ssh/new"
        else
            echo "🔧 Génération nouvelle clé SSH..."
            echo ""
            read -p "Entrez votre email GitHub: " github_email
            
            # Générer clé SSH
            ssh-keygen -t ed25519 -C "$github_email" -f ~/.ssh/id_ed25519 -N ""
            
            # Ajouter à l'agent SSH
            eval "$(ssh-agent -s)"
            ssh-add ~/.ssh/id_ed25519
            
            echo ""
            echo "✅ Clé SSH générée !"
            echo ""
            echo "📋 Votre clé publique:"
            cat ~/.ssh/id_ed25519.pub
            echo ""
            echo "📋 Copiez cette clé et ajoutez-la à GitHub:"
            echo "   https://github.com/settings/ssh/new"
        fi
        
        echo ""
        read -p "Avez-vous ajouté la clé à GitHub ? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Tester la connexion SSH
            echo "🧪 Test connexion SSH..."
            if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                echo "✅ SSH configuré avec succès !"
                
                # Configurer le remote SSH
                git remote set-url origin "$REPO_URL_SSH"
                echo "✅ Remote configuré en SSH"
                echo ""
                echo "🚀 Vous pouvez maintenant pusher:"
                echo "   git push -u origin native_clean"
            else
                echo "❌ Connexion SSH échouée"
                echo "Vérifiez que la clé est bien ajoutée à GitHub"
            fi
        fi
        ;;
        
    3)
        echo ""
        echo "📱 Configuration GitHub CLI"
        echo "=========================="
        echo ""
        
        # Vérifier si gh est installé
        if command -v gh &>/dev/null; then
            echo "✅ GitHub CLI déjà installé"
        else
            echo "📦 Installation GitHub CLI..."
            
            # Installation pour Ubuntu/Debian
            if command -v apt &>/dev/null; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
                sudo apt install gh
            else
                echo "❌ Installation automatique non supportée"
                echo "Installez manuellement : https://cli.github.com/"
                exit 1
            fi
        fi
        
        # Authentification
        echo "🔐 Authentification avec GitHub..."
        gh auth login
        
        # Configurer le remote
        git remote set-url origin "$REPO_URL_HTTPS"
        
        echo ""
        echo "✅ GitHub CLI configuré !"
        echo "🚀 Vous pouvez maintenant pusher avec gh:"
        echo "   gh repo create RSS_LLM_Pipeline_Stable --public"
        echo "   git push -u origin native_clean"
        ;;
        
    4)
        echo ""
        echo "ℹ️  Diagnostics et Aide"
        echo "====================="
        echo ""
        
        # Informations actuelles
        echo "📋 Configuration Git actuelle:"
        echo "   User: $(git config --global user.name || echo "Non configuré")"
        echo "   Email: $(git config --global user.email || echo "Non configuré")"
        echo "   Remote: $(git remote get-url origin 2>/dev/null || echo "Non configuré")"
        echo ""
        
        # Tester connectivité
        echo "🌐 Test connectivité GitHub:"
        if curl -s --head https://github.com >/dev/null; then
            echo "   ✅ Connexion internet OK"
        else
            echo "   ❌ Problème connexion internet"
        fi
        
        # Vérifier SSH
        echo ""
        echo "🔐 Clés SSH disponibles:"
        if [ -f ~/.ssh/id_ed25519.pub ]; then
            echo "   ✅ Clé ED25519 trouvée"
        elif [ -f ~/.ssh/id_rsa.pub ]; then
            echo "   ✅ Clé RSA trouvée"
        else
            echo "   ❌ Aucune clé SSH trouvée"
        fi
        
        # GitHub CLI
        echo ""
        echo "📱 GitHub CLI:"
        if command -v gh &>/dev/null; then
            echo "   ✅ Installé ($(gh --version | head -n1))"
            if gh auth status &>/dev/null; then
                echo "   ✅ Authentifié"
            else
                echo "   ❌ Non authentifié"
            fi
        else
            echo "   ❌ Non installé"
        fi
        
        echo ""
        echo "💡 Recommandations:"
        echo "   1. Si première fois : Utilisez GitHub CLI (option 3)"
        echo "   2. Si expérimenté : Utilisez SSH (option 2)"
        echo "   3. Si problème : Utilisez Personal Token (option 1)"
        ;;
        
    5)
        echo "❌ Configuration annulée"
        exit 0
        ;;
        
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo ""
echo "🔗 Repository cible:"
echo "   https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable"
echo ""
echo "📝 Notes importantes:"
echo "   • N'utilisez JAMAIS votre mot de passe GitHub avec HTTPS"
echo "   • Utilisez toujours un Personal Access Token avec HTTPS"
echo "   • SSH est plus sécurisé pour un usage fréquent"
echo "   • GitHub CLI simplifie l'authentification"
