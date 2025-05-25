#!/usr/bin/env python3
"""
Script d'initialisation des dossiers de domaines
À exécuter après modification de sources.json
"""

import json
import os
import sys
from pathlib import Path

def load_sources_config(config_path="config/sources.json"):
    """Charge la configuration sources.json"""
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ Fichier {config_path} non trouvé")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Erreur JSON dans {config_path}: {e}")
        sys.exit(1)

def create_domain_folders(config, base_path="obsidian_vault/articles"):
    """Crée tous les dossiers de domaines définis dans la config"""
    
    if "domains" not in config:
        print("⚠️ Aucun domaine trouvé dans sources.json")
        return
    
    base_dir = Path(base_path)
    base_dir.mkdir(parents=True, exist_ok=True)
    
    created_folders = []
    existing_folders = []
    
    for domain_key, domain_config in config["domains"].items():
        # Récupérer le nom du dossier
        folder_name = domain_config.get("output_folder", domain_key)
        folder_path = base_dir / folder_name
        
        if folder_path.exists():
            existing_folders.append(folder_name)
            print(f"✅ {folder_name} (existe déjà)")
        else:
            folder_path.mkdir(parents=True, exist_ok=True)
            created_folders.append(folder_name)
            print(f"🆕 {folder_name} (créé)")
            
            # Créer un fichier README dans chaque dossier
            readme_content = f"""# {domain_config.get('label', domain_key)}

{domain_config.get('emoji', '📁')} **Domaine** : {domain_key}
**Alert Level** : {domain_config.get('default_alert', 'info')}

## Mots-clés de classification
{', '.join(domain_config.get('critical_keywords', []))}

## Description
Articles classifiés automatiquement dans cette catégorie de fraude/sécurité.

---
*Généré automatiquement par le système RSS + LLM*
"""
            readme_path = folder_path / "README.md"
            readme_path.write_text(readme_content, encoding='utf-8')
    
    # Résumé
    print(f"\n📊 RÉSUMÉ :")
    print(f"   🆕 Dossiers créés : {len(created_folders)}")
    print(f"   ✅ Dossiers existants : {len(existing_folders)}")
    
    if created_folders:
        print(f"\n🆕 NOUVEAUX DOSSIERS :")
        for folder in created_folders:
            print(f"   - {folder}")

def create_moc_index(config, base_path="obsidian_vault"):
    """Crée un index MOC (Map of Content) pour Obsidian"""
    
    moc_content = """# 🚨 Index Veille Anti-Fraude

## 📂 Domaines de Surveillance

"""
    
    for domain_key, domain_config in config.get("domains", {}).items():
        emoji = domain_config.get('emoji', '📁')
        label = domain_config.get('label', domain_key)
        folder = domain_config.get('output_folder', domain_key)
        alert = domain_config.get('default_alert', 'info')
        
        moc_content += f"### {emoji} {label}\n"
        moc_content += f"**Alert Level**: {alert.upper()}\n"
        moc_content += f"**Dossier**: [[articles/{folder}/]]\n\n"
    
    moc_content += """
## 🎯 Sources Configurées

"""
    
    # Ajouter les sources par priorité
    sources = config.get("sources", [])
    for priority in ["high", "medium", "low"]:
        priority_sources = [s for s in sources if s.get("priority") == priority]
        if priority_sources:
            moc_content += f"### {priority.title()} Priority\n"
            for source in priority_sources:
                flag = "🇫🇷" if "FR" in source.get("keywords", []) else "🇺🇸" if "EN" in source.get("keywords", []) else "🌐"
                moc_content += f"- {flag} **{source['name']}** - {source.get('domain', 'N/A')}\n"
            moc_content += "\n"
    
    moc_content += f"""
---
*Dernière mise à jour : {Path().cwd()}*
*Articles traités automatiquement par le pipeline RSS + LLM*
"""
    
    moc_path = Path(base_path) / "INDEX_VEILLE_FRAUDE.md"
    moc_path.write_text(moc_content, encoding='utf-8')
    print(f"📋 Index MOC créé : {moc_path}")

def main():
    print("🚀 Initialisation des dossiers de domaines Anti-Fraude")
    print("=" * 60)
    
    # Charger la config
    config = load_sources_config()
    
    # Créer les dossiers
    create_domain_folders(config)
    
    # Créer l'index MOC
    create_moc_index(config)
    
    print("\n✅ Initialisation terminée !")
    print("💡 Vous pouvez maintenant lancer le pipeline RSS")

if __name__ == "__main__":
    main()