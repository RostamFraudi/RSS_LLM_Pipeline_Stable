# ⚙️ Configuration - RSS LLM Pipeline Native

## 📂 Structure Configuration

```
config/
├── sources.json    # Sources RSS
└── prompts.json    # Templates prompts
```

## 🔧 Sources RSS

Éditer `config/sources.json` :

```json
{
  "sources": [
    {
      "name": "Example Security Feed",
      "url": "https://example.com/feed.xml",
      "category": "cyber_security",
      "enabled": true
    }
  ]
}
```

## 🎯 Domaines Supportés

- `fraude_investissement` - Arnaques investissement
- `fraude_paiement` - Fraudes bancaires
- `fraude_president_cyber` - FOVI & CEO fraud
- `fraude_ecommerce` - Fraudes e-commerce
- `supply_chain_cyber` - Attaques supply chain
- `intelligence_economique` - Veille stratégique
- `fraude_crypto` - Fraudes crypto
- `cyber_investigations` - Investigations cyber

## 🚀 Ports Services

- **8080** : Classification TinyLlama
- **8081** : Résumés Qwen2
- **15000** : API Python
- **1880** : Node-RED (optionnel)
