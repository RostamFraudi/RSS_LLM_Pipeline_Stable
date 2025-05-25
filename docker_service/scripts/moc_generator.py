#!/usr/bin/env python3
"""
Générateur automatique de MOCs pour Obsidian
Intégration Pipeline RSS + LLM v2.0
Version portable - chemins relatifs
"""

import os
import json
import datetime
from pathlib import Path

def get_project_root():
    """Retourne le répertoire racine du projet de manière portable"""
    # Quand exécuté dans Docker, utilise le mapping
    if os.path.exists('/obsidian_vault'):
        return Path('/obsidian_vault')
    
    # Quand exécuté localement, remonte au projet
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent  # scripts -> docker_service -> root
    obsidian_path = project_root / 'obsidian_vault'
    
    # Créer le dossier s'il n'existe pas
    obsidian_path.mkdir(exist_ok=True)
    return obsidian_path

def update_moc_stats():
    """Met à jour les stats temps réel dans les MOCs"""
    
    # Paths portables
    obsidian_path = get_project_root()
    articles_path = obsidian_path / "articles"
    
    # Créer le dossier articles s'il n'existe pas
    articles_path.mkdir(exist_ok=True)
    
    # Statistiques globales
    stats = {
        'total_articles': 0,
        'domains': {},
        'last_sync': datetime.datetime.now().isoformat(),
        'critical_alerts': 0
    }
    
    # Scanner tous les domaines
    for domain_folder in articles_path.iterdir():
        if domain_folder.is_dir():
            domain = domain_folder.name
            article_count = len(list(domain_folder.glob("*.md")))
            
            stats['domains'][domain] = {
                'count': article_count,
                'folder': domain
            }
            stats['total_articles'] += article_count
    
    # Mettre à jour le MOC principal
    update_main_moc(stats, obsidian_path)
    
    return stats

def update_main_moc(stats, obsidian_path):
    """Met à jour MOC Veille 2025.md avec stats temps réel"""
    
    template = f"""# 🎯 MOC Veille Stratégique 2025
> **Tableau de bord central** - Pipeline RSS + LLM v2.0 • {stats['total_articles']} articles

---

## 🔄 Vue Temps Réel

### 📊 Articles par Domaine (7 derniers jours)
```dataview
TABLE WITHOUT ID
  "🎯 " + domain_label as "Domaine",
  "📊 " + count(rows) as "Articles",
  "🚨 " + length(filter(rows, (r) => r.alert_level = "critical")) as "Critiques",
  "🔥 " + length(filter(rows, (r) => contains(r.strategic_tags, "#urgent"))) as "Urgents"
FROM "articles"
WHERE date >= date(today) - dur(7 days) AND domain != null
GROUP BY domain_label
SORT count(rows) DESC
```

### 🚨 Alertes Critiques Actives
```dataview
TABLE WITHOUT ID
  "🚨" + file.link as "Alerte",
  domain_label as "Domaine", 
  dateformat(date, "dd/MM HH:mm") as "Détection"
FROM "articles"
WHERE alert_level = "critical" 
  AND date >= date(today) - dur(3 days)
SORT date DESC
LIMIT 5
```

## 🧭 Navigation Domaines

### 🚨 [[Veille Fraude MOC|Veille Fraude & Cybersécurité]]
```dataview
TABLE WITHOUT ID
  "📊 " + count(rows) as "Articles 7j",
  "🔴 " + length(filter(rows, (r) => r.alert_level = "critical")) as "Critiques"
FROM "articles"
WHERE domain = "veille_fraude" AND date >= date(today) - dur(7 days)
```

### 🚀 [[Innovation Tech MOC|Innovation Technologique]]
```dataview
TABLE WITHOUT ID
  "📊 " + count(rows) as "Articles 7j",
  "🔥 " + length(filter(rows, (r) => contains(r.strategic_tags, "#breakthrough"))) as "Percées"
FROM "articles"
WHERE domain = "innovation_tech" AND date >= date(today) - dur(7 days)
```

### 💰 [[Finance Crypto MOC|Finance & Crypto]]
```dataview
TABLE WITHOUT ID
  "📊 " + count(rows) as "Articles 7j",
  "📈 " + length(filter(rows, (r) => contains(r.strategic_tags, "#market-trend"))) as "Tendances"
FROM "articles"
WHERE domain = "finance_crypto" AND date >= date(today) - dur(7 days)
```

### 📱 [[Actualite Tech MOC|Actualité Technologique]]
```dataview
TABLE WITHOUT ID
  "📊 " + count(rows) as "Articles 7j",
  "💼 " + length(filter(rows, (r) => contains(r.strategic_tags, "#funding"))) as "Financements"
FROM "articles"
WHERE domain = "actualite_tech" AND date >= date(today) - dur(7 days)
```

## 🧠 Réseau de Connaissances

### 💡 Concepts les Plus Connectés
```dataview
TABLE WITHOUT ID
  obsidian_concepts as "🔗 Concept",
  count(rows) as "📊 Mentions"
FROM "articles"
WHERE date >= date(today) - dur(30 days) 
  AND length(obsidian_concepts) > 0
FLATTEN obsidian_concepts
GROUP BY obsidian_concepts
SORT count(rows) DESC
LIMIT 8
```

### 🏷️ Tags Stratégiques Actifs  
```dataview
TABLE WITHOUT ID
  strategic_tags as "🏷️ Tag",
  count(rows) as "📊 Usage"
FROM "articles"
WHERE date >= date(today) - dur(7 days) 
  AND length(strategic_tags) > 0
FLATTEN strategic_tags  
GROUP BY strategic_tags
SORT count(rows) DESC
LIMIT 10
```

## 📈 Performance Pipeline

### 🎯 Qualité Classification
```dataview
TABLE WITHOUT ID
  domain_label as "Domaine",
  round(average(number(confidence)), 1) + "%" as "Confiance Moy.",
  count(rows) as "Échantillon"
FROM "articles"  
WHERE date >= date(today) - dur(7 days) AND confidence != null
GROUP BY domain_label
SORT average(number(confidence)) DESC
```

### 📡 Sources les Plus Productives
```dataview
TABLE WITHOUT ID
  source as "📡 Source",
  count(rows) as "📊 Articles",
  domain_label as "🎯 Domaine Principal"
FROM "articles"
WHERE date >= date(today) - dur(7 days)
GROUP BY source
SORT count(rows) DESC
LIMIT 8
```

## ⚡ Actions Rapides

### 🎯 Aujourd'hui
- [ ] Analyser alertes critiques 🔴
- [ ] Valider nouveaux concepts 💡  
- [ ] Mettre à jour indicateurs 📊
- [ ] Synthèse cross-domaines 🔗

## 🔗 Navigation

**[[Index Pipeline]]** • **[[Configuration]]** • **[[Documentation]]**

---

*Dernière sync : {stats['last_sync'][:16]} • Articles : {stats['total_articles']} • Pipeline v2.0*"""

    # Écrire le MOC avec chemin portable
    moc_path = obsidian_path / "MOC Veille 2025.md"
    with open(moc_path, 'w', encoding='utf-8') as f:
        f.write(template)
    
    print(f"✅ MOC principal mis à jour : {stats['total_articles']} articles")

def create_domain_mocs(obsidian_path):
    """Crée/met à jour les MOCs par domaine"""
    
    domains = {
        'veille_fraude': {
            'title': '🚨 Veille Fraude & Cybersécurité',
            'desc': 'Sécurité • Fraudes • Cyberattaques • Vulnérabilités'
        },
        'innovation_tech': {
            'title': '🚀 Innovation Technologique', 
            'desc': 'IA • Blockchain • Recherche • Technologies Émergentes'
        },
        'finance_crypto': {
            'title': '💰 Finance & Crypto',
            'desc': 'Cryptomonnaies • DeFi • Marchés • Régulation'
        },
        'actualite_tech': {
            'title': '📱 Actualité Technologique',
            'desc': 'Startups • Business • Produits • Acquisitions'
        }
    }
    
    for domain, config in domains.items():
        create_domain_moc(domain, config, obsidian_path)

def create_domain_moc(domain, config, obsidian_path):
    """Crée un MOC spécifique à un domaine"""
    
    template = f"""{config['title']}
> **{config['desc']}**

---

## 🔴 Alertes & Priorités

```dataview
TABLE WITHOUT ID
  "🚨 " + file.link as "Article",
  alert_level as "🚦 Niveau",
  dateformat(date, "dd/MM HH:mm") as "Détection"
FROM "articles"
WHERE domain = "{domain}" 
  AND alert_level IN ["critical", "alert"]
  AND date >= date(today) - dur(7 days)
SORT date DESC
LIMIT 10
```

## 📊 Vue d'Ensemble

```dataview
TABLE WITHOUT ID
  source as "📡 Source",
  count(rows) as "📊 Articles",
  round(average(number(confidence)), 1) + "%" as "🎯 Qualité"
FROM "articles"
WHERE domain = "{domain}" 
  AND date >= date(today) - dur(7 days)
GROUP BY source
SORT count(rows) DESC
```

## 🧠 Concepts Principaux

```dataview
TABLE WITHOUT ID
  obsidian_concepts as "💡 Concept",
  count(rows) as "📊 Usage"
FROM "articles"
WHERE domain = "{domain}" 
  AND date >= date(today) - dur(14 days)
  AND length(obsidian_concepts) > 0
FLATTEN obsidian_concepts
GROUP BY obsidian_concepts
SORT count(rows) DESC
LIMIT 8
```

## 📈 Activité Récente

```dataview
LIST WITHOUT ID "📰 " + file.link + " (" + alert_level + ")"
FROM "articles"
WHERE domain = "{domain}"
  AND date >= date(today) - dur(3 days)
SORT date DESC
LIMIT 15
```

## 🔗 Navigation

[[MOC Veille 2025|🏠 Hub Principal]] • [[Analytics Dashboard|📊 Stats]]

---

*Mis à jour automatiquement • Pipeline v2.0*"""

    # Écrire le MOC du domaine avec chemin portable
    moc_path = obsidian_path / f"{config['title'].split(' ', 1)[1]} MOC.md"
    with open(moc_path, 'w', encoding='utf-8') as f:
        f.write(template)
    
    print(f"✅ MOC {domain} créé")

def create_article_folders(obsidian_path):
    """Crée les dossiers d'articles avec gestion portable"""
    articles_path = obsidian_path / "articles"
    
    # Dossiers pour tous les domaines
    folders = [
        "veille_fraude",
        "innovation_tech", 
        "finance_crypto",
        "actualite_tech",
        # Anciens dossiers pour compatibilité
        "ia", "dev", "business", "cloud", "securite", "autre"
    ]
    
    for folder in folders:
        folder_path = articles_path / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        print(f"📁 Dossier créé: {folder}")

if __name__ == "__main__":
    print("🚀 Génération MOCs (version portable)...")
    
    # Obtenir le chemin projet de manière portable
    obsidian_path = get_project_root()
    print(f"📁 Chemin Obsidian: {obsidian_path}")
    
    # Créer dossiers
    create_article_folders(obsidian_path)
    
    # Générer MOCs
    stats = update_moc_stats()
    create_domain_mocs(obsidian_path)
    
    print(f"✅ MOCs générés : {stats['total_articles']} articles indexés")
    print(f"📍 Localisation: {obsidian_path}")