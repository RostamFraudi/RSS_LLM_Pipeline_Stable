"""
RSS LLM Service Native v3.2
Optimisé avec llama.cpp local - VERSION ASYNC PRODUCTION
"""

from flask import Flask, request, jsonify
import json
import time
import logging
from pathlib import Path
from llama_client import LlamaClient
import asyncio

# Configuration logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Détermination des chemins absolus pour plus de robustesse
BASE_DIR = Path(__file__).resolve().parent.parent
CONFIG_DIR = BASE_DIR / "config"

def load_json_config(filename: str):
    """Charge un fichier JSON depuis le dossier config"""
    path = CONFIG_DIR / filename
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Erreur chargement {filename}: {e}")
        return {}

# Chargement initial des configurations
config = load_json_config("sources.json")
prompts = load_json_config("prompts.json")

# Initialisation du client LLM
llama_client = LlamaClient(config.get('llama_config', {}), prompts=prompts)

@app.route('/generate_metadata', methods=['POST'])
async def generate_metadata():
    """Endpoint principal - Classification + métadonnées avec hashtags Obsidian"""
    try:
        data = request.json
        if not data:
            return jsonify({"error": "Données JSON manquantes"}), 400

        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        if not title:
            return jsonify({"error": "Le titre est requis"}), 400

        start_time = time.time()
        
        # 1. Classification avec llama.cpp (Asynchrone)
        domains_config = config.get('domains', {})
        available_domains = list(domains_config.keys())
        
        classification = await llama_client.classify_domain(title, content, available_domains)
        domain = classification['domain']
        
        # 2. Informations du domaine
        domain_info = domains_config.get(domain, {})
        
        # 3. Génération tags et alertes
        alert_level = determine_alert_level(title, content, domain)
        tags = generate_tags_with_hashtags(title, content, domain)
        concepts = extract_concepts_with_hashtags(title, content, domain)
        
        total_time = time.time() - start_time
        
        result = {
            "domain": domain,
            "domain_label": domain_info.get('label', domain),
            "domain_emoji": domain_info.get('emoji', '📄'),
            "confidence": classification['confidence'],
            "classification_method": classification['method'],
            "alert_level": alert_level,
            "tags": tags,
            "obsidian_concepts": concepts,
            "obsidian_tags": generate_obsidian_tags(domain, alert_level, tags),
            "output_folder": domain_info.get('output_folder', domain),
            "processing_time": total_time,
            "llm_used": classification['method'].startswith('llama'),
            "version": "3.2_native_async"
        }
        
        logger.info(f"✅ Classification réussie: {domain} ({classification['confidence']}%)")
        return jsonify(result)
        
    except Exception as e:
        logger.exception(f"Erreur dans generate_metadata: {e}")
        return jsonify({"error": "Erreur interne du serveur", "details": str(e)}), 500

@app.route('/summarize', methods=['POST'])
async def summarize():
    """Génération de résumé avec llama.cpp (Asynchrone)"""
    try:
        data = request.json
        if not data:
            return jsonify({"error": "Données JSON manquantes"}), 400

        title = data.get('title', '')
        content = data.get('content', '')
        domain = data.get('domain', 'cyber_investigations')

        if not title or not content:
            return jsonify({"error": "Le titre et le contenu sont requis"}), 400

        summary_result = await llama_client.generate_summary(title, content, domain)

        return jsonify({
            "summary": summary_result['summary'],
            "domain": domain,
            "processing_time": summary_result['processing_time'],
            "method": summary_result['method'],
            "version": "3.2_native_async"
        })

    except Exception as e:
        logger.exception(f"Erreur dans summarize: {e}")
        return jsonify({"error": "Erreur interne du serveur", "details": str(e)}), 500

@app.route('/health', methods=['GET'])
async def health():
    """Health check détaillé avec status des serveurs llama.cpp"""
    try:
        llama_status = await llama_client.health_check()

        return jsonify({
            "status": "ok",
            "service": "RSS LLM Service v3.2 Native Async",
            "llama_servers": llama_status,
            "config_paths": {
                "base": str(BASE_DIR),
                "config": str(CONFIG_DIR)
            },
            "version": "3.2_native_async"
        })

    except Exception as e:
        logger.error(f"Health check a échoué: {e}")
        return jsonify({"status": "error", "error": str(e)}), 500

# --- Fonctions utilitaires ---

def determine_alert_level(title: str, content: str, domain: str) -> str:
    """Détermine le niveau d'alerte basé sur des mots-clés"""
    text = (title + " " + content).lower()

    critical_keywords = ['breach', 'attack', 'urgent', 'critical', 'exploit', '0-day', 'zero-day', 'fuite']
    watch_keywords = ['warning', 'risk', 'threat', 'vulnerability', 'menace', 'risque', 'vulnerabilité']

    if any(word in text for word in critical_keywords):
        return 'urgent'
    elif any(word in text for word in watch_keywords):
        return 'watch'
    else:
        return 'info'

def generate_tags_with_hashtags(title: str, content: str, domain: str) -> list:
    """Génère des tags avec hashtags formatés pour Obsidian"""
    tags = []
    
    # Tag de domaine
    tags.append(f"#{domain.replace('_', '-')}")
    
    text = (title + " " + content).lower()
    
    # Mapping mots-clés -> hashtags
    tag_mapping = {
        'urgent': '#alerte-urgente',
        'critical': '#critique', 
        'breach': '#fuite-donnees',
        'attack': '#cyberattaque',
        'fraud': '#fraude-confirmee',
        'scam': '#arnaque',
        'malware': '#malware',
        'phishing': '#hameconnage',
        'ransomware': '#rançongiciel',
        'apt': '#menace-persistante',
        'zero-day': '#zero-day',
        'vulnerability': '#vulnerabilite'
    }
    
    for keyword, hashtag in tag_mapping.items():
        if keyword in text:
            tags.append(hashtag)
    
    # Tags géographiques
    geo_mapping = {
        'france': '#france',
        'europe': '#europe', 
        'usa': '#etats-unis',
        'china': '#chine',
        'russie': '#russie',
        'ukraine': '#ukraine'
    }
    
    for geo, hashtag in geo_mapping.items():
        if geo in text:
            tags.append(hashtag)
            
    return sorted(list(set(tags)))

def extract_concepts_with_hashtags(title: str, content: str, domain: str) -> list:
    """Extrait des concepts clés avec hashtags"""
    concepts = []
    
    domain_concepts = {
        'fraude_investissement': ['#Fraude-Financière', '#Protection-Investisseurs', '#AMF', '#Ponzi'],
        'fraude_paiement': ['#Sécurité-Bancaire', '#Moyens-de-Paiement', '#PCI-DSS', '#Skimming'],
        'cyber_investigations': ['#Cybersécurité', '#Investigation-Numérique', '#Forensic', '#CERT'],
        'fraude_crypto': ['#Cryptomonnaies', '#Blockchain-Security', '#DeFi-Risks', '#Rug-Pull'],
        'supply_chain_cyber': ['#Supply-Chain', '#Third-Party-Risk', '#Vendor-Security'],
        'fraude_president_cyber': ['#FOVI', '#CEO-Fraud', '#Business-Email-Compromise', '#Social-Engineering'],
        'fraude_ecommerce': ['#E-commerce-Security', '#Online-Fraud', '#Payment-Security']
    }
    
    base_concepts = domain_concepts.get(domain, ['#Cybersécurité', '#Veille-Technologique'])
    concepts.extend(base_concepts)
    
    text = (title + " " + content).lower()
    
    # Organisations et technos courantes
    entities = {
        'microsoft': '#Microsoft', 'google': '#Google', 'apple': '#Apple',
        'amazon': '#Amazon', 'paypal': '#PayPal', 'visa': '#Visa',
        'mastercard': '#MasterCard', 'windows': '#Windows', 'linux': '#Linux',
        'android': '#Android', 'ios': '#iOS', 'outlook': '#Outlook'
    }
    
    for key, hashtag in entities.items():
        if key in text:
            concepts.append(hashtag)
            
    return sorted(list(set(concepts)))

def generate_obsidian_tags(domain: str, alert_level: str, tags: list) -> str:
    """Formate la ligne de tags pour le haut du fichier Obsidian"""
    all_tags = [f"#{domain.replace('_', '-')}", f"#{alert_level}"] + tags
    return ' '.join(sorted(list(set(all_tags))))

if __name__ == '__main__':
    logger.info("🚀 Démarrage RSS LLM Service Native v3.2 (Mode Développement)")
    # En production, utilisez gunicorn ou un serveur ASGI
    app.run(host='0.0.0.0', port=15000, debug=False)
