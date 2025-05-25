# 🎯 MOC Veille Stratégique 2025
> **Tableau de bord central** - Pipeline RSS + LLM v2.0 • 0 articles

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

*Dernière sync : 2025-05-25T14:35 • Articles : 0 • Pipeline v2.0*