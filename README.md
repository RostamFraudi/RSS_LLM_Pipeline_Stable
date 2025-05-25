# 🚀 RSS + LLM Pipeline - Version Portable

> **Pipeline RSS automatisé** avec classification IA locale et intégration Obsidian  
> ✅ **100% portable** • 🐳 **Docker** • 🤖 **LLM local** • 📝 **Auto-résumés**

---

## ⚡ Usage Quotidien (30 secondes)

### 🌅 **Démarrage Rapide Quotidien**
```bash
# Windows - Démarrage ultra-rapide des conteneurs existants
start_containers.bat
```
> **Optimisé quotidien** : Démarre directement les conteneurs sans rebuild  
> **Temps** : ~15 secondes • **Auto-ouverture** Node-RED • **Monitoring** intégré

### 🌙 **Arrêt Propre**
```bash
# Windows - Arrêt propre des conteneurs
stop_containers.bat
```

### 🔧 **Scripts Disponibles**
| Script | Usage | Description |
|--------|-------|-------------|
| **`start_containers.bat`** | 🌅 **Quotidien** | Démarre conteneurs existants (ultra-rapide) |
| **`stop_containers.bat`** | 🌙 **Quotidien** | Arrête proprement les conteneurs |
| `deployment/start_pipeline.bat` | 🔧 Installation | Premier démarrage avec build complet |
| `deployment/stop_pipeline.bat` | 🛑 Maintenance | Arrêt docker-compose complet |

> **💡 Astuce** : Pour l'usage quotidien, utilisez `start_containers.bat` (rapide) au lieu des scripts deployment (lents)

---

## 🎯 Installation Initiale (5 minutes)

### 📋 Prérequis
- **Docker Desktop** (Windows/Mac/Linux)
- **4+ Go RAM** disponible  
- **2+ Go stockage** libre

### ⚡ Première Installation
```bash
# 1. Cloner le projet
git clone https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable.git
cd RSS_LLM_Pipeline_Stable

# 2. Premier démarrage avec build (Windows)
deployment\start_pipeline.bat

# 3. Premier démarrage avec build (Linux/Mac)
chmod +x deployment/start_pipeline.sh && ./deployment/start_pipeline.sh
```

### 🔄 **Après Installation - Usage Quotidien**
```bash
# ✅ Utilisez les scripts rapides à la racine :
start_containers.bat    # 🌅 Matin (15s)
stop_containers.bat     # 🌙 Soir (5s)

# ❌ Évitez les scripts deployment (lents) :
# deployment\start_pipeline.bat  # Build complet (2-5 min)
```

### 🌐 Validation
- **LLM Service** : http://localhost:15000/health
- **Node-RED** : http://localhost:18880 (ouvert automatiquement)
- **Articles** : `obsidian_vault/articles/`

---

## 🏗️ Architecture Portable

### 📁 Structure du Projet
```
RSS_LLM_Pipeline_Stable/
├── 🚀 start_containers.bat  # ⭐ Démarrage quotidien (RAPIDE)
├── 🛑 stop_containers.bat   # ⭐ Arrêt quotidien (RAPIDE)
├── 📁 deployment/           # Scripts maintenance (lents)
│   ├── start_pipeline.bat   # Premier démarrage avec build
│   ├── test_pipeline.bat    # Tests automatisés
│   ├── stop_pipeline.bat    # Arrêt docker-compose complet
│   └── view_logs.bat        # Monitoring logs
├── 🐳 docker_service/       # Services containerisés
│   ├── docker-compose.yml   # Orchestration
│   ├── llm_service/         # API Classification + Résumés
│   ├── nodered_custom/      # Flux RSS automatisé
│   └── scripts/             # Utilitaires (MOC generator)
├── ⚙️ config/              # Configuration portable
│   ├── sources.json         # Sources RSS + domaines
│   └── prompts.json         # Prompts LLM personnalisés
├── 📝 obsidian_vault/       # Sortie articles (créé auto)
│   └── articles/            # Articles par domaine
├── 🔧 node_red_data/        # Données Node-RED (créé auto)
└── 📚 documentation/        # Guides utilisateur
```

### 🎯 **Optimisation Performance**
- **Scripts quotidiens** : `docker start` direct (pas de docker-compose)
- **Scripts maintenance** : `docker-compose` complet avec build
- **Auto-détection** : Conteneurs existants vs nouveau build
- **Temps de démarrage** : 15s (quotidien) vs 2-5min (build complet)

### 🔗 Portabilité Garantie
- ✅ **Chemins relatifs** partout (`../config`, `%~dp0..`)
- ✅ **Variables environnement** Docker uniquement
- ✅ **Auto-création** dossiers manquants
- ✅ **Détection architecture** automatique
- ✅ **Aucune dépendance** système externe

---

## 🤖 Services & APIs

### 🧠 LLM Service (Port 15000)
```bash
# Endpoints disponibles
POST /classify      # Classification V1 (5 catégories)
POST /classify_v2   # Classification V2 (4 domaines)
POST /summarize_v2  # Résumés structurés
POST /generate_metadata  # Métadonnées complètes
GET  /health        # Santé service
GET  /status        # Statut détaillé
```

### 🔧 Node-RED (Port 18880)
- **Interface graphique** : Configuration flux
- **Déclencheur automatique** : Toutes les 30 minutes
- **Sources RSS** : Multiples feeds simultanés
- **Pipeline complet** : RSS → LLM → Obsidian

### 📁 Structure Obsidian
```
obsidian_vault/
├── articles/
│   ├── veille_fraude/      # 🚨 Cybersécurité + Fraudes
│   ├── innovation_tech/    # 🚀 IA + Blockchain + Recherche
│   ├── finance_crypto/     # 💰 Crypto + DeFi + Marchés
│   └── actualite_tech/     # 📱 Startups + Business Tech
├── MOC Veille 2025.md      # Dashboard principal
└── [Domaine] MOC.md        # MOCs par domaine
```

---

## ⚙️ Configuration

### 📡 Sources RSS (`config/sources.json`)
```json
{
  "sources": [
    {
      "name": "OpenAI Blog",
      "url": "https://openai.com/blog/rss.xml",
      "domain": "innovation_tech",
      "priority": "high",
      "keywords": ["ai", "research", "model"]
    }
  ]
}
```

### 🎯 Domaines Supportés
| Domaine | Description | Mots-clés |
|---------|-------------|-----------|
| `veille_fraude` | 🚨 Cybersécurité, fraudes, attaques | security, breach, hack |
| `innovation_tech` | 🚀 IA, blockchain, recherche | ai, innovation, research |
| `finance_crypto` | 💰 Crypto, DeFi, marchés | bitcoin, defi, trading |
| `actualite_tech` | 📱 Startups, business tech | startup, funding, product |

---

## 🧪 Tests & Validation

### 🔍 Tests Automatisés
```bash
# Test complet du pipeline
deployment\test_pipeline.bat
```

### 📊 Métriques Qualité
- **Classification** : 85-95% précision
- **Résumés** : Structures par domaine
- **Performance** : <2s par article
- **Disponibilité** : 99%+ (auto-restart)

---

## 🛠️ Maintenance & Monitoring

### 📋 **Monitoring Quotidien**
```bash
# ✅ Démarrage rapide avec monitoring intégré
start_containers.bat

# 📊 Logs en temps réel (si besoin)
deployment\view_logs.bat

# 📈 Statut conteneurs
docker ps --filter "name=rss_"
```

### 🔄 **Mises à jour Configuration**
```bash
# Mise à jour sources RSS
# → Modifier config/sources.json
# → Redémarrer : docker restart rss_nodered

# Mise à jour prompts LLM  
# → Modifier config/prompts.json
# → Redémarrer : docker restart rss_llm_service

# Mise à jour flux Node-RED
# → Interface web : http://localhost:18880
```

### 🧹 **Maintenance Avancée**
```bash
# Arrêt propre quotidien
stop_containers.bat

# Rebuild complet (si problème)
deployment\stop_pipeline.bat
deployment\start_pipeline.bat

# Nettoyage Docker complet
docker system prune -f
```

---

## 🚀 Workflow Quotidien Optimal

### 🌅 **Routine Matinale (15 secondes)**
1. **Double-clic** : `start_containers.bat`
2. **Auto-ouverture** : Node-RED (http://localhost:18880)
3. **Vérification** : Dashboard articles générés
4. **C'est tout !** Pipeline actif pour la journée

### 📊 **Surveillance Continue**
- **Articles** : Générés automatiquement toutes les 30min
- **Monitoring** : Onglet Debug dans Node-RED
- **Health** : http://localhost:15000/health (auto-vérifié)

### 🌙 **Arrêt en Fin de Journée (5 secondes)**
1. **Double-clic** : `stop_containers.bat`
2. **Vérification** : Conteneurs arrêtés proprement
3. **Économies** : Ressources libérées

---

## 🚀 Déploiement Production

### 🌐 Ports & Sécurité
- **Ports exposés** : 15000 (LLM), 18880 (Node-RED)
- **Réseau Docker** : `rss_llm_network` (isolé)
- **Volumes persistants** : node_red_data, obsidian_vault
- **Healthchecks** : Intégrés avec auto-restart

### ⚡ Performance
- **RAM** : 8 Go recommandé
- **CPU** : 2+ cœurs pour LLM
- **Stockage** : ~100 Mo par 1000 articles
- **Réseau** : Bande passante RSS négligeable

### 🔧 Variables d'Environnement
```yaml
# docker-compose.yml
environment:
  - PYTHONUNBUFFERED=1        # Logs temps réel
  - FLASK_ENV=production      # Mode production
  - TZ=Europe/Paris          # Timezone Node-RED
```

---

## 🆘 Dépannage

### ❌ Problèmes Courants

**Conteneurs ne démarrent pas (scripts quotidiens)**
```bash
# Vérifier existence conteneurs
docker ps -a --filter "name=rss_"

# Si manquants : rebuild complet
deployment\start_pipeline.bat
```

**LLM Service ne répond pas**
```bash
# Vérifier logs
docker logs rss_llm_service

# Restart rapide
docker restart rss_llm_service
```

**Node-RED interface vide**
```bash
# Vérifier logs
docker logs rss_nodered

# Restart rapide  
docker restart rss_nodered
```

**Performance dégradée**
```bash
# Utiliser scripts rapides quotidiens au lieu de docker-compose
start_containers.bat    # ✅ Rapide
# vs
deployment\start_pipeline.bat  # ❌ Lent (rebuild)
```

### 🔧 Reset Complet
```bash
# Tout supprimer et recommencer
stop_containers.bat
docker system prune -f
deployment\start_pipeline.bat
```

---

## 📈 Roadmap

### ✅ Version Actuelle (v2.0)
- Classification 4 domaines + mots-clés intelligents
- Résumés structurés adaptatifs
- MOCs Obsidian automatiques
- Pipeline Docker stable
- **Scripts quotidiens optimisés** (démarrage 15s vs 5min)

### 🎯 Prochaines Versions
- [ ] **v2.1** : Déduplication articles + Interface web config
- [ ] **v2.2** : Notifications (email, Slack) + Analytics avancés  
- [ ] **v3.0** : Multi-modèles LLM + API publique + Mode cluster

---

## 🤝 Contribution

### 🔧 Développement Local
```bash
# Fork du repo
git clone [YOUR_FORK]

# Développement avec hot-reload
deployment\start_pipeline.bat

# Tests après modifications
deployment\test_pipeline.bat
```

### 📝 Ajout Fonctionnalités
1. **Sources RSS** : Ajouter dans `config/sources.json`
2. **Nouveaux domaines** : Modifier `llm_service/app.py`
3. **Prompts LLM** : Personnaliser `config/prompts.json`
4. **Flux Node-RED** : Export depuis interface web

---

## 📄 Licence

**MIT License** - Utilisation libre pour projets personnels et commerciaux

---

## 🔗 Liens Utiles

- **Scripts quotidiens** : `start_containers.bat` / `stop_containers.bat`
- **Documentation** : `documentation/GUIDE_DEMARRAGE.md`
- **Configuration** : `config/` (sources RSS + prompts)
- **Logs** : `docker logs rss_llm_service` / `docker logs rss_nodered`
- **Health Checks** : http://localhost:15000/health

**🎉 Votre pipeline RSS + LLM portable est prêt !**

*Dernière mise à jour : 24/05/2025 • Version 2.0 Stable + Scripts Quotidiens Optimisés*