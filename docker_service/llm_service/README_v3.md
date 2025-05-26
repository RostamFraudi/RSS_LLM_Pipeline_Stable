# 🚀 RSS LLM Service v3.0 - Documentation

## 📋 Vue d'ensemble

Le service `app_v3.py` est une refonte complète qui implémente une **vraie utilisation de LLM** avec un système de fallback intelligent.

### 🎯 Principales améliorations

1. **Classification LLM réelle** : Utilise DeBERTa pour une classification zero-shot
2. **Tags intelligents** : En anglais, sans doublons, contextuels
3. **Architecture hybride** : LLM quand disponible, règles en fallback
4. **Résumés dynamiques** : Générés par DistilBART ou templates
5. **API unifiée** : Endpoint `/generate_metadata` qui fait tout

## 🏗️ Architecture

```
┌─────────────────┐
│  Article RSS    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│ Classification  │────►│ LLM DeBERTa  │ (si disponible)
└────────┬────────┘     └──────────────┘
         │                      │
         │              ┌───────▼────────┐
         │              │ Fallback Rules │ (si LLM indisponible)
         │              └────────────────┘
         ▼
┌─────────────────┐
│ Tags + Alertes  │ (Génération intelligente)
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│    Résumé       │────►│ DistilBART   │ (si disponible)
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐
│ Métadonnées     │ (JSON unifié)
└─────────────────┘
```

## 📡 Endpoints API

### 1. `/generate_metadata` (Principal)

**Méthode** : POST  
**Description** : Endpoint unifié qui retourne toutes les métadonnées

**Requête** :
```json
{
  "title": "Major Data Breach at TechCorp",
  "content": "A critical vulnerability has been exploited...",
  "source": "KrebsOnSecurity"
}
```

**Réponse** :
```json
{
  "domain": "cyber_investigations",
  "domain_label": "Cyber Investigations",
  "confidence": 87.5,
  "classification_method": "llm_zero_shot",
  "alert_level": "critical",
  "tags": ["cybercrime", "investigation", "data-breach", "urgent"],
  "obsidian_concepts": ["Cybercrime", "Digital Forensics", "Threat Intelligence"],
  "output_folder": "cyber-investigations",
  "processing_time": 0.342,
  "llm_used": true,
  "version": "3.0_hybrid"
}
```

### 2. `/classify` (Simple)

**Description** : Classification seule (utilise `/generate_metadata` en interne)

### 3. `/summarize` (Résumé)

**Requête** :
```json
{
  "title": "Article title",
  "content": "Article content...",
  "domain": "fraude_paiement"
}
```

**Réponse** :
```json
{
  "summary": "💳 **Payment Security Alert**: Article title\n\nLLM-generated summary here...",
  "domain": "fraude_paiement",
  "processing_time": 1.23,
  "method": "llm",
  "version": "3.0"
}
```

### 4. Endpoints de monitoring

- `/health` : Vérification rapide
- `/status` : Status détaillé avec modèles chargés
- `/config/info` : Configuration actuelle
- `/reload_config` : Recharger la configuration

### 5. Compatibilité v2

- `/classify_v2` → redirige vers `/generate_metadata`
- `/summarize_v2` → redirige vers `/summarize`

## 🔧 Configuration

### Modèles utilisés

1. **Classification** : `MoritzLaurer/DeBERTa-v3-base-mnli-fever-anli`
   - Zero-shot classification
   - Très précis pour la catégorisation

2. **Résumé** : `sshleifer/distilbart-cnn-12-6`
   - Modèle léger et rapide
   - Résumés de 50-150 mots

### Domaines supportés

```python
- fraude_investissement     # Investment fraud
- fraude_paiement          # Payment fraud
- fraude_president_cyber   # CEO fraud
- fraude_ecommerce         # E-commerce fraud
- supply_chain_cyber       # Supply chain attacks
- intelligence_economique  # Economic intelligence
- fraude_crypto           # Crypto fraud
- cyber_investigations    # General cybercrime
```

### Tags générés

- **Langue** : Anglais uniquement
- **Format** : lowercase-with-hyphens
- **Exemples** : `cybercrime`, `data-breach`, `urgent`, `high-confidence`
- **Maximum** : 6 tags par article

## 🚀 Utilisation

### Docker

Modifier le Dockerfile pour utiliser `app_v3.py` :

```dockerfile
# Dans llm_service/Dockerfile
CMD ["python", "app_v3.py"]
```

### Test local

```bash
# Installer les dépendances
pip install transformers torch flask

# Lancer le service
python app_v3.py
```

### Test des endpoints

```bash
# Test classification avec LLM
curl -X POST http://localhost:5000/generate_metadata \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Ransomware Attack on Hospital",
    "content": "A major ransomware attack has encrypted...",
    "source": "SecurityWeek"
  }'

# Vérifier le status
curl http://localhost:5000/status
```

## ⚡ Performance

| Opération | Avec LLM | Sans LLM (fallback) |
|-----------|----------|---------------------|
| Classification | ~300ms | ~50ms |
| Tags | ~10ms | ~10ms |
| Résumé | ~1.2s | ~50ms |
| Total `/generate_metadata` | ~1.5s | ~100ms |

## 🔄 Mode Fallback

Si les modèles LLM ne peuvent pas être chargés :

1. Classification → Analyse par mots-clés
2. Résumé → Templates prédéfinis
3. Tags → Règles statiques
4. Performance → 10x plus rapide mais moins précis

## 🐛 Troubleshooting

### Erreur de chargement des modèles

```
❌ Erreur chargement modèles: [Errno 28] No space left on device
```

**Solution** : Les modèles nécessitent ~2GB d'espace. Nettoyer le disque ou utiliser le mode fallback.

### Timeout sur classification

**Solution** : Réduire la taille du contenu envoyé (limite à 1000 caractères pour la classification).

### Tags en français apparaissent

**Solution** : Vérifier que vous utilisez bien `app_v3.py` et non l'ancien `app.py`.

## 📈 Évolutions futures

1. **Cache Redis** pour éviter de reclassifier les mêmes articles
2. **Batch processing** pour traiter plusieurs articles d'un coup
3. **Fine-tuning** des modèles sur votre corpus spécifique
4. **API asynchrone** avec FastAPI pour meilleure performance

---

**Version** : 3.0  
**Date** : 26/05/2025  
**Auteur** : Pipeline RSS + LLM v3 Team
