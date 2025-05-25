# 🎯 MOC Veille Stratégique 2025
> **Tableau de bord central** - Pipeline RSS + LLM v2.0

---

## 🔄 Vue Temps Réel

### 📊 Articles par Domaine
```dataview
TABLE domain_label, alert_level, confidence
WHERE contains(file.path, "articles")
GROUP BY domain_label
SORT domain_label
```

### 🚨 Alertes Critiques
```dataview
TABLE file.link, domain_label, alert_level
WHERE contains(file.path, "articles") AND alert_level = "critical"
SORT file.mtime DESC
LIMIT 10
```

## 🧭 Navigation Domaines

### 🚨 Veille Fraude & Cybersécurité
```dataview
TABLE file.name, alert_level, confidence
WHERE contains(file.path, "articles") AND domain = "veille_fraude"
SORT file.mtime DESC
LIMIT 5
```

### 🚀 Innovation Technologique  
```dataview
TABLE file.name, alert_level, confidence
WHERE contains(file.path, "articles") AND domain = "innovation_tech"
SORT file.mtime DESC
LIMIT 5
```

### 💰 Finance & Crypto
```dataview
TABLE file.name, alert_level, confidence
WHERE contains(file.path, "articles") AND domain = "finance_crypto"
SORT file.mtime DESC
LIMIT 5
```

### 📱 Actualité Technologique
```dataview
TABLE file.name, alert_level, confidence
WHERE contains(file.path, "articles") AND domain = "actualite_tech"
SORT file.mtime DESC
LIMIT 5
```

## 📈 Sources Actives

```dataview
TABLE source, domain_label
WHERE contains(file.path, "articles")
GROUP BY source
SORT source
```

## 🧠 Concepts Obsidian

```dataview
TABLE file.name, obsidian_concepts
WHERE contains(file.path, "articles") AND obsidian_concepts != null
SORT file.mtime DESC
LIMIT 10
```

## ⚡ Actions Rapides

- [ ] Analyser alertes critiques 🔴
- [ ] Valider nouveaux concepts 💡  
- [ ] Synthèse cross-domaines 🔗

---

*Pipeline v2.0 • Articles indexés automatiquement*