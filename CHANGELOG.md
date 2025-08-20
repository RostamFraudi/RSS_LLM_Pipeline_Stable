# 📋 CHANGELOG

## [3.1.1] - 2025-08-20

### 🎯 **MIGRATION MAJEURE : Docker → Linux Native**

#### 🚀 **Ajouté**
- **Architecture llama.cpp native** remplaçant l'environnement Docker
- **TinyLlama 1.1B Q4** pour classification ultra-rapide (700MB)
- **Qwen2 0.5B Q4** pour résumés intelligents (350MB)
- **Installation automatique** via `./install.sh`
- **Scripts de démarrage** unifiés (`./start_pipeline.sh`)
- **Tests intégrés** (`./test_pipeline.sh`)
- **Support GPU CUDA** automatique avec fallback CPU
- **Documentation complète** (installation, configuration, troubleshooting)
- **Monitoring temps réel** des ressources système

#### 🔄 **Modifié**
- **Performance** : -83% RAM (2GB vs 12GB), -81% stockage, -75% temps démarrage
- **Latence classification** : 150ms (vs 300ms précédemment)
- **API endpoints** adaptés pour backends llama.cpp
- **Structure projet** organisée en modules natifs
- **Configuration** simplifiée pour sources RSS

#### 🗑️ **Supprimé**
- **Docker** : Dockerfile, docker-compose.yml, images containers
- **Transformers/PyTorch** : Remplacement par llama.cpp C++
- **Modèles HuggingFace** : Migration vers GGUF optimisés
- **Dépendances ML lourdes** : Réduction drastique requirements
- **Scripts de migration temporaires** : Nettoyage repository

#### 🐛 **Corrigé**
- **Fuites mémoire** Docker containers
- **Lenteur** inférence transformers
- **Instabilité** GPU containers
- **Complexité** installation et maintenance

#### ⚠️ **Breaking Changes**
- **Installation** : Nouvelle procédure native requise
- **URLs services** : Nouveaux ports (8080, 8081, 15000)
- **Dépendances** : Requirements Python complètement modifiées
- **Configuration** : Adaptation nécessaire pour migration

---

## [3.1.0] - 2025-07-15

### 🐳 **Version Docker (Dépréciée)**
- Pipeline RSS avec transformers en containers Docker
- Classification avec modèles HuggingFace
- API Python avec PyTorch/CUDA
- Node-RED containerisé
- Interface Obsidian

---

## [3.0.0] - 2025-06-01

### 🎉 **Release Initiale**
- Pipeline RSS automatisé
- Classification 8 domaines métier
- Génération résumés intelligents
- Export format Obsidian
- Interface Node-RED

---

## 🎯 **Format de Versioning**

Ce projet suit le [Semantic Versioning](https://semver.org/) :
- **MAJOR** : Changements incompatibles d'API
- **MINOR** : Ajout fonctionnalités compatibles
- **PATCH** : Corrections bugs compatibles

## 🔗 **Liens**

- **Repository** : https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable
- **Documentation** : `docs/` dans le repository
- **Issues** : GitHub Issues pour bug reports
- **Releases** : GitHub Releases pour téléchargements
