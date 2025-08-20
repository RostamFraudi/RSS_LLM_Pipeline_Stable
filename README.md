# 🦙 RSS LLM Pipeline Native

> **Pipeline RSS automatisé** avec llama.cpp local pour performances optimales  
> **Gains** : -83% RAM, -81% stockage, -75% temps démarrage vs Docker

## 🚀 Installation Rapide

```bash
# Clone repository
git clone https://github.com/RostamFraudi/RSS_LLM_Pipeline_Stable.git
cd RSS_LLM_Pipeline_Stable

# Installation automatique
./install.sh

# Démarrage
./start_pipeline.sh
```

## 📊 Architecture

```
RSS_LLM_Pipeline_Native/
├── 🦙 llama.cpp/              # Serveurs llama.cpp (auto-installé)
├── 🐍 native_service/         # API Flask légère
├── ⚙️ config/                 # Configuration JSON
├── 📜 scripts/                # Scripts utilitaires
├── 📚 docs/                   # Documentation complète
└── 📝 obsidian_vault/        # Articles générés
```

## 🎯 Modèles Utilisés

- **TinyLlama 1.1B Q4** (700MB) : Classification rapide
- **Qwen2 0.5B Q4** (350MB) : Résumés intelligents
- **Total** : ~1GB vs 8GB+ transformers

## 🔧 Services

### Ports par défaut
- **Classification** : http://localhost:8080 (TinyLlama)
- **Résumés** : http://localhost:8081 (Qwen2)
- **API Service** : http://localhost:15000

### Domaines Supportés
- `fraude_investissement` 💰 - Arnaques investissement
- `fraude_paiement` 💳 - Fraudes bancaires
- `fraude_president_cyber` 🎭 - FOVI & CEO fraud
- `fraude_ecommerce` 🛒 - Fraudes e-commerce
- `supply_chain_cyber` 🔗 - Attaques supply chain
- `intelligence_economique` 🕵️ - Veille stratégique
- `fraude_crypto` ₿ - Fraudes crypto
- `cyber_investigations` 🔍 - Investigations cyber

## 🧪 Tests

```bash
# Test complet
./test_pipeline.sh

# Test classification
curl -X POST http://localhost:15000/generate_metadata \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Security breach detected","source":"Test"}'

# Test résumé
curl -X POST http://localhost:15000/summarize \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Article content","domain":"cyber_investigations"}'
```

## 📈 Performance

| Métrique | Docker | Native | Gain |
|----------|--------|--------|------|
| RAM | 12GB | 2GB | -83% |
| Stockage | 8GB | 1.5GB | -81% |
| Démarrage | 60s | 15s | -75% |
| Classification | 300ms | 150ms | -50% |

## 🛠️ Maintenance

```bash
# Arrêt propre
pkill -f "llama-server"

# Monitoring en temps réel
./scripts/monitoring.sh

# Vérification santé
./test_pipeline.sh
```

## 📚 Documentation

- **[Installation](docs/INSTALL.md)** - Guide détaillé d'installation
- **[Configuration](docs/CONFIGURATION.md)** - Configuration sources RSS
- **[Dépannage](docs/TROUBLESHOOTING.md)** - Résolution problèmes

## 🎯 Workflow

1. **Installation** : `./install.sh`
2. **Configuration** : Éditer `config/sources.json`
3. **Démarrage** : `./start_pipeline.sh`
4. **Monitoring** : `./scripts/monitoring.sh`

## 🔄 Pipeline de Données

```
📡 Sources RSS → 🦙 Classification → 📝 Résumé → 📄 Obsidian
```

1. **Collecte** : Flux RSS configurés
2. **Classification** : TinyLlama 1.1B (domaines métier)
3. **Résumé** : Qwen2 0.5B (synthèse intelligente)
4. **Export** : Articles Obsidian formatés

## ⚡ Optimisations

- **🦙 llama.cpp** : Inférence C++ optimisée
- **📦 GGUF Q4** : Modèles quantifiés
- **🐍 Flask léger** : API minimale sans Transformers
- **🔧 Scripts modulaires** : Installation et maintenance automatisées

## 🆘 Support

- **Issues** : GitHub Issues
- **Logs** : `./scripts/monitoring.sh`
- **Tests** : `./test_pipeline.sh`
- **Reset** : Supprimer `venv/`, `llama.cpp/`, relancer `./install.sh`

---

*RSS LLM Pipeline Native v3.0 - Optimisé avec llama.cpp pour production*
