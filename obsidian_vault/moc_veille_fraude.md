# 🚨 Veille Fraude & Cybersécurité
> **Sécurité • Fraudes • Cyberattaques • Vulnérabilités**

---

## 🔴 Alertes Critiques

```dataview
TABLE strategic_tags, domain_label
WHERE contains(file.path, "articles") AND alert_level = "critical"
SORT file.mtime DESC
```

## 📊 Vue d'Ensemble

```dataview
TABLE domain_label
WHERE contains(file.path, "articles")
GROUP BY domain_label
```

## 🧠 Concepts Sécurité

### [[Cybersécurité]]
```dataview
TABLE domain_label
WHERE contains(file.path, "articles") AND alert_level = "critical"
SORT file.mtime DESC
```

### [[Fraude Financière]]
```dataview
LIST WITHOUT ID file.link + " (" + alert_level + ")"
FROM "articles"
WHERE contains(obsidian_concepts, "Fraude Financière")
  AND date >= date(today) - dur(14 days)
SORT date DESC
```

### [[Vulnérabilités]]
```dataview
LIST WITHOUT ID file.link + " (" + alert_level + ")"
FROM "articles"
WHERE contains(obsidian_concepts, "Vulnérabilités")
  AND date >= date(today) - dur(14 days)
SORT date DESC
```

## 🎯 Classification Menaces

### 🔥 Haute Priorité
```dataview
LIST WITHOUT ID "🔴 " + file.link
FROM "articles"
WHERE domain = "veille_fraude" 
  AND alert_level = "critical"
  AND date >= date(today) - dur(30 days)
SORT date DESC
```

### ⚠️ Surveillance
```dataview
LIST WITHOUT ID "🟡 " + file.link
FROM "articles" 
WHERE domain = "veille_fraude"
  AND alert_level = "watch"
  AND date >= date(today) - dur(7 days)
SORT date DESC
```

## 📈 Tendances Sécurité

```dataview
TABLE WITHOUT ID
  dateformat(date, "WW-yyyy") as "Semaine",
  count(rows) as "📊 Incidents",
  length(filter(rows, (r) => r.alert_level = "critical")) as "🔴 Critiques"
FROM "articles"
WHERE domain = "veille_fraude" 
  AND date >= date(today) - dur(60 days)
GROUP BY dateformat(date, "WW-yyyy")
SORT dateformat(date, "WW-yyyy") DESC
```

## 🔗 Navigation

[[MOC Veille 2025|🏠 Hub Principal]] • [[Innovation Tech MOC|🚀 Innovation]] • [[Analytics Dashboard|📊 Stats]]

---

*Mise à jour automatique • Pipeline v2.0*