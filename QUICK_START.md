# 🚀 Guide Démarrage Rapide

> **Pipeline RSS + LLM opérationnel en 5 minutes !**  
> De zéro à l'analyse automatique d'articles avec IA locale

---

## ⚡ Installation Express (5 min)

### 🎯 **Étape 1 : Prérequis** (2 min)
```bash
# Vérifier Docker Desktop installé
docker --version

# Si pas installé : https://www.docker.com/products/docker-desktop
```

### 📦 **Étape 2 : Récupérer le Projet** (1 min)
```bash
# Cloner le repo
git clone https://github.com/votre-repo/RSS_LLM_Pipeline_Stable.git
cd RSS_LLM_Pipeline_Stable

# Copier configuration exemple
copy config\sources.example.json config\sources.json
```

### 🔧 **Étape 3 : Configuration Sources** (1 min)
```bash
# Éditer config/sources.json avec vos sources RSS préférées
# Ou garder les exemples pour tester
```

### 🚀 **Étape 4 : Premier Démarrage** (2-5 min)
```bash
# IMPORTANT : Premier démarrage avec build
deployment\start_pipeline.bat

# Attendre que les services se lancent...
# LLM Service : http://localhost:15000/health ✅
# Node-RED : http://localhost:18880 ✅
```

### ✅ **Étape 5 : Validation**
- **Interface Node-RED** s'ouvre automatiquement
- **Premier pipeline** se lance automatiquement  
- **Articles générés** dans `obsidian_vault/articles/`

---

## 🌅 Usage Quotidien (15 secondes)

**Après installation, usage ultra-rapide :**

```bash
# 🌅 Matin : Démarrage rapide (15s)
start_containers.bat

# 🌙 Soir : Arrêt propre (5s)  
stop_containers.bat
```

**⚠️ Important** : Utilisez les scripts racine (rapides) pour l'usage quotidien, pas `deployment/` (lents avec build)

---

## 📊 Premiers Résultats

### 🎯 **Après 30 minutes**, vous aurez :

| Domaine | Articles | Tags Exemple |
|---------|----------|--------------|
| 🚨 **Veille Fraude** | 5-10 | `#security-alert` `#urgent` |
| 🚀 **Innovation Tech** | 8-15 | `#innovation` `#breakthrough` |
| 💰 **Finance Crypto** | 3-8 | `#market-trend` `#crypto-news` |
| 📱 **Actualité Tech** | 10-20 | `#business-news` `#funding` |

### 📝 **Structure Article Généré**
```markdown
---
title: "Article Title"
domain: innovation_tech
alert_level: info
tags: ["#innovation", "#tech-trend"]
concepts: "[[Intelligence Artificielle]] [[Innovation Technologique]]"
---

# 🚀 Article Title

**Domaine** : Innovation Technologique  
**Source** : OpenAI Blog

## 🔍 Résumé Structuré
• **Technologie** : Développement technique
• **Applications** : Potentiel élevé  
• **Suivi** : Évolution à surveiller

## 🔗 Concepts Liés
- [[Intelligence Artificielle]]
- [[Innovation Technologique]]
```

---

## 🔧 Personnalisation Express

### ⚙️ **Ajouter Vos Sources RSS** (2 min)

**Éditer `config/sources.json` :**
```json
{
  "sources": [
    {
      "name": "Votre Blog Tech Préféré",
      "url": "https://exemple.com/rss.xml",
      "domain": "actualite_tech",
      "priority": "high",
      "keywords": ["startup", "innovation"]
    }
  ]
}
```

**Redémarrer :**
```bash
docker restart rss_nodered
```

### 🏷️ **Personnaliser Tags** (5 min)

**Modifier `docker_service/llm_service/app.py` :**
```python
# Ajouter vos tags personnalisés
if 'quantum' in text:
    tags.append("#quantum-tech")
```

**Redémarrer :**
```bash
docker restart rss_llm_service
```

---

## 🔍 Monitoring & Debug

### 📊 **Vérifier Santé Services**
```bash
# LLM Service
curl http://localhost:15000/health

# Node-RED (interface web)
# → http://localhost:18880

# Logs temps réel
docker logs -f rss_llm_service
docker logs -f rss_nodered
```

### 🐛 **Problèmes Courants**

| Problème | Solution Rapide |
|----------|-----------------|
| Services ne démarrent pas | `diagnostic.bat` |
| Pas d'articles générés | Vérifier sources RSS dans config |
| Interface Node-RED vide | Attendre 2-3 min puis recharger |
| Résumés en anglais | Redémarrer LLM service |

### 🔧 **Reset Complet**
```bash
stop_containers.bat
docker system prune -f
deployment\start_pipeline.bat
```

---

## 🎯 Prochaines Étapes

### 📚 **Approfondir** (15 min)
- Lire [Système de Tagging](documentation/TAGGING_SYSTEM.md)
- Explorer [Node-RED Interface](http://localhost:18880)
- Consulter [Guide Scripts](SCRIPTS_README.md)

### 🎨 **Personnaliser** (30 min)
- Configurer sources RSS spécifiques
- Adapter prompts LLM à vos besoins
- Créer nouveaux domaines de classification

### 🚀 **Étendre** (1h+)
- Ajouter notifications (email, Slack)
- Intégrer avec vos outils existants
- Contribuer au projet ([Guide](CONTRIBUTING.md))

---

## 🆘 Support Rapide

### 💬 **Besoin d'Aide ?**
1. **Consulter** [FAQ](documentation/FAQ.md)
2. **Lancer** `diagnostic.bat` pour debug
3. **Ouvrir** [Issue GitHub](https://github.com/your-repo/issues)

### 🤝 **Communauté**
- 💡 **Idées** : [Discussions GitHub](https://github.com/your-repo/discussions)
- 🐛 **Bugs** : [Issues](https://github.com/your-repo/issues)
- 🔧 **Contributions** : [Guide](CONTRIBUTING.md)

---

## ✅ Checklist Succès

- [ ] ✅ Docker Desktop installé et fonctionnel
- [ ] ✅ Projet cloné et configuration copiée
- [ ] ✅ Premier build réussi (`deployment/start_pipeline.bat`)
- [ ] ✅ Services accessibles (15000 + 18880)
- [ ] ✅ Premiers articles générés dans `obsidian_vault/`
- [ ] ✅ Scripts quotidiens testés (`start_containers.bat`)
- [ ] ✅ Node-RED interface explorée
- [ ] ✅ Configuration sources personnalisée

**🎉 Félicitations ! Votre pipeline RSS + LLM est opérationnel !**

---

**⏱️ Temps total** : 5-10 minutes installation + 5 minutes personnalisation  
**🔄 Usage quotidien** : 15 secondes démarrage / 5 secondes arrêt  
**📈 Résultats** : Articles analysés et tagués automatiquement toutes les 30 minutes

*Prêt pour l'analyse intelligente de votre veille technologique !* 🚀
