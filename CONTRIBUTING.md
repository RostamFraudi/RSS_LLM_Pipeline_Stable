# 🤝 Guide de Contribution

Merci de votre intérêt pour contribuer au **RSS + LLM Pipeline** ! 🎉

## 🚀 Façons de Contribuer

### 💡 **Suggestions & Bugs**
- Ouvrir une **Issue** pour signaler un bug
- Proposer des **nouvelles fonctionnalités**
- Partager des **sources RSS intéressantes**
- Améliorer la **documentation**

### 🔧 **Contributions Code**

#### **Configuration Simple**
- **Sources RSS** : Ajouter dans `config/sources.json`
- **Prompts LLM** : Personnaliser `config/prompts.json`
- **Tags personnalisés** : Modifier `llm_service/app.py`

#### **Développement Avancé**
- **Nouveaux domaines** : Étendre la classification
- **Améliorations LLM** : Optimiser l'analyse
- **Intégrations** : APIs externes, notifications
- **Performance** : Optimisations Docker/Python

## 📋 Processus de Contribution

### 1. **Setup Développement**
```bash
# Fork le repo
git clone https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable.git
cd RSS_LLM_Pipeline_Stable

# Premier build (5-10 min)
deployment\start_pipeline.bat

# Vérifier fonctionnement
curl http://localhost:15000/health
```

### 2. **Développement**
```bash
# Créer branche
git checkout -b feature/ma-nouvelle-fonctionnalite

# Développer et tester
# ... modifications ...

# Restart services si besoin
docker restart rss_llm_service
```

### 3. **Tests**
```bash
# Tester manuellement
start_containers.bat

# Tester API
curl -X POST http://localhost:15000/classify_v2 \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"test article","source":"test"}'
```

### 4. **Pull Request**
- **Commit** avec messages clairs
- **Push** vers votre fork
- **Ouvrir PR** avec description détaillée

## ✅ Standards de Qualité

### **Code**
- ✅ **Fonctionnel** : Code testé localement
- ✅ **Documenté** : Commentaires pour logic complexe
- ✅ **Portable** : Chemins relatifs, pas de hardcoding
- ✅ **Performance** : Pas de régression de vitesse

### **Documentation**
- ✅ **README** mis à jour si nouvelle fonctionnalité
- ✅ **Exemples** d'utilisation fournis
- ✅ **Configuration** expliquée

### **Sécurité**
- ❌ **Pas de secrets** dans le code
- ❌ **Pas de données perso** dans les exemples
- ✅ **Validation input** pour nouvelles APIs

## 🎯 Idées de Contributions

### 🔰 **Niveau Débutant**
- Ajouter **nouvelles sources RSS** dans exemples
- Améliorer **documentation** avec screenshots
- Traduire **messages d'erreur** en français
- Créer **templates de configuration** pour domaines spécifiques

### 🔨 **Niveau Intermédiaire**
- **Nouveaux domaines** : santé, éducation, environnement
- **Tags avancés** : sentiment analysis, trending detection
- **Notifications** : email, Slack, Discord
- **Interface web** : configuration visuelle

### 🚀 **Niveau Avancé**
- **Multi-modèles LLM** : comparaison classifications
- **Performance** : parallélisation, optimisations
- **Analytics** : dashboard métriques qualité
- **CI/CD** : tests automatisés, déploiement

## 🏷️ **Conventions**

### **Commits**
```
feat: ajouter domaine santé tech
fix: corriger classification crypto  
docs: mettre à jour guide tagging
perf: optimiser temps réponse LLM
```

### **Branches**
```
feature/nouveau-domaine-sante
fix/bug-classification-crypto
docs/guide-configuration
perf/optimisation-llm
```

### **Issues**
- **Bug** : Template avec étapes reproduction
- **Feature** : Description cas d'usage + bénéfices
- **Question** : Tag `question` pour demandes d'aide

## 📞 Support & Questions

### 🔍 **Avant de Demander**
1. Consulter **documentation/** 
2. Vérifier **Issues existantes**
3. Tester avec **configuration exemple**
4. Lancer **diagnostic.bat** pour debug

### 💬 **Canaux d'Aide**
- **Issues GitHub** : Questions publiques
- **Discussions** : Échanges communauté  
- **Pull Requests** : Reviews code

## 🌟 **Reconnaissance**

Tous les contributeurs sont mentionnés dans :
- 📄 **README.md** - Section contributeurs
- 📋 **CHANGELOG.md** - Crédits par version
- 🎉 **Releases** - Notes de version

## 📚 **Ressources Utiles**

### **Documentation Projet**
- [Système de Tagging](documentation/TAGGING_SYSTEM.md)
- [Scripts Usage](SCRIPTS_README.md)
- [Architecture](RSS_LLM_Pipeline_Stable/README.md#architecture-portable)

### **Technologies**
- **Docker** : https://docs.docker.com/
- **Node-RED** : https://nodered.org/docs/
- **Flask** : https://flask.palletsprojects.com/
- **Transformers** : https://huggingface.co/docs/transformers/

---

**🎉 Merci de faire grandir ce projet ensemble !**

*Pour toute question : ouvrir une Issue avec le label `question`*
