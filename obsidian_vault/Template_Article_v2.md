---
title: \"{{title}}\"
source: \"{{source}}\"
domain: \"{{domain}}\"
domain_label: \"{{domain_label}}\"
classification_v2: true
date: {{date}}
url: \"{{url}}\"
tags: {{tags}}
processed: {{processed_date}}
obsidian_concepts: {{obsidian_concepts}}
strategic_tags: {{strategic_tags}}
alert_level: \"{{alert_level}}\"
confidence: {{confidence}}
processing_stats:
  method: \"{{classification_method}}\"
  processing_time: \"{{processing_time}}\"
  version: \"2.0_hybrid\"
---
# 📰 {{title}}

> **{{domain_label}}** | **{{source}}** | {{formatted_date}} | {{alert_emoji}} {{alert_level}}

{{summary}}

## 🔗 Informations

- **Source** : {{source}}
- **Domaine** : {{domain_label}} (`{{domain}}`)
- **Date de publication** : {{formatted_date}}
- **URL originale** : [📖 Lire l'article complet]({{url}})
- **Niveau d'alerte** : {{alert_emoji}} {{alert_level}}
- **Traité le** : {{processed_formatted}}

## 🧠 Réseau de Connaissances

### Concepts liés
{{#each obsidian_concepts}}
- {{this}}
{{/each}}

### Navigation stratégique  
- [[{{domain_label}} - Index]] • [[MOC Veille {{current_year}}]]
- [[Trends {{domain}}]] • [[Analytics Dashboard]]

### Tags de veille
{{#each strategic_tags}}
{{this}} 
{{/each}}

## 📝 Contenu

{{content}}

---

## 🔄 Métadonnées Pipeline

<details>
<summary>📊 Informations de traitement v2.0</summary>

- **Version** : Système Hybride v2.0
- **Classification** : {{classification_method}}
- **Confiance** : {{confidence}}%
- **Temps de traitement** : {{processing_time}}s
- **Domaine détecté** : {{domain}}
- **Liens générés** : {{obsidian_concepts_count}}
- **Tags stratégiques** : {{strategic_tags_count}}
- **Fichier** : `{{filename}}`

</details>

## 📈 Actions de Suivi

- [ ] Analyser l'impact stratégique
- [ ] Vérifier les connexions avec [[Projets en cours]]
- [ ] Mettre à jour [[Tableau de Bord Veille]]
- [ ] Partager si pertinence > seuil critique

---

*Analysé automatiquement par Pipeline RSS + LLM v2.0 • {{processed_formatted}}*

<!-- Navigation rapide -->
[[◀️ Précédent]] | [[Index Veille]] | [[Suivant ▶️]]`
}