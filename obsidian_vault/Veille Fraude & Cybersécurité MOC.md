🚨 Veille Fraude & Cybersécurité
> **Sécurité • Fraudes • Cyberattaques • Vulnérabilités**

---

## 🔴 Alertes & Priorités

```dataview
TABLE WITHOUT ID
  "🚨 " + file.link as "Article",
  alert_level as "🚦 Niveau",
  dateformat(date, "dd/MM HH:mm") as "Détection"
FROM "articles"
WHERE domain = "veille_fraude" 
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
WHERE domain = "veille_fraude" 
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
WHERE domain = "veille_fraude" 
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
WHERE domain = "veille_fraude"
  AND date >= date(today) - dur(3 days)
SORT date DESC
LIMIT 15
```

## 🔗 Navigation

[[MOC Veille 2025|🏠 Hub Principal]] • [[Analytics Dashboard|📊 Stats]]

---

*Mis à jour automatiquement • Pipeline v2.0*