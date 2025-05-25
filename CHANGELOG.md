# 📈 Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
et ce projet suit [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### À Venir
- Interface web de configuration
- Linux compatible
- Analytics avancés
- Support multi-langues + Pipeline de traduction

---

## [2.0.0] - 2025-05-24

### 🎉 Version Majeure - Pipeline Complet

#### ✨ Nouvelles Fonctionnalités
- **Classification intelligente v2.0** : 4 domaines (veille_fraude, innovation_tech, finance_crypto, actualite_tech)
- **Système de tagging automatique** : Tags urgence, domaine, contextuels
- **Concepts Obsidian** : Génération automatique liens `[[]]`
- **Scripts quotidiens optimisés** : `start_containers.bat` / `stop_containers.bat` (15s vs 5min)
- **Pipeline Node-RED** : Flux RSS → LLM → Obsidian complet
- **Architecture Docker** : Services containerisés avec healthchecks

#### 🔧 Améliorations
- **Performance** : Classification <0.5s par article
- **Portabilité** : Chemins relatifs, configuration JSON
- **Robustesse** : Gestion d'erreurs, fallbacks automatiques
- **Documentation** : Guides complets avec exemples

#### 🏷️ Système de Tagging
- **Tags urgence** : `#urgent`, `#important`, `#watch`, `#info`
- **Tags domaine** : `#security-alert`, `#innovation`, `#market-trend`, `#business-news`
- **Tags contextuels** : `#breakthrough`, `#funding`, `#regulation`
- **Concepts Obsidian** : Extraction automatique avec liens

#### 🤖 LLM Service v2.0
- **Endpoints v2** : `/classify_v2`, `/summarize_v2`, `/generate_metadata`
- **Classification hybride** : IA + règles expertes
- **Résumés structurés** : Adaptés par domaine
- **Métadonnées enrichies** : Confidence, alertes, concepts

### 🔄 Migration depuis v1.x
1. Sauvegarder configuration existante
2. Utiliser nouveaux scripts quotidiens
3. Configurer sources dans `config/sources.json`
4. Tester avec `start_containers.bat`

---

## [1.2.0] - 2025-05-23

### ✨ Ajouts
- Classification par mots-clés basique
- Résumés automatiques simples
- Sauvegarde Markdown basique

### 🔧 Corrections
- Stabilité parsing RSS
- Gestion erreurs Docker

---

## [1.1.0] - 2025-05-22

### ✨ Ajouts
- Support multi-sources RSS
- Pipeline Node-RED initial
- Configuration Docker-compose

### 🔧 Corrections
- Encodage caractères spéciaux
- Timeouts HTTP

---

## [1.0.0] - 2025-05-21

### 🎉 Version Initiale

#### ✨ Fonctionnalités
- Lecture RSS basique
- Service LLM minimal
- Export Markdown simple

---

## 🏷️ Types de Modifications

- ✨ **Nouvelles fonctionnalités** : `Added`
- 🔧 **Corrections** : `Fixed` 
- 🔄 **Modifications** : `Changed`
- ⚠️ **Dépréciations** : `Deprecated`
- 🗑️ **Suppressions** : `Removed`
- 🔒 **Sécurité** : `Security`

## 📊 Statistiques Versions

| Version | Date       | Fonctionnalités | Performance | Documentation |
| ------- | ---------- | --------------- | ----------- | ------------- |
| v2.0.0  | 2025-05-24 | 🟢 Complètes    | 🟢 <0.5s    | 🟢 Exhaustive |
| v1.2.0  | 2025-05-23 | 🟡 Basiques     | 🟡 <2s      | 🟡 Partielle  |
| v1.0.0  | 2025-05-21 | 🔴 Minimales    | 🔴 <10s     | 🔴 Basique    |

---

**📝 Format** : [Version] - Date  
**🔗 Liens** : [Comparer versions](https://github.com/your-repo/compare)  
**📋 Issues** : [Milestone actuel](https://github.com/your-repo/milestones)
