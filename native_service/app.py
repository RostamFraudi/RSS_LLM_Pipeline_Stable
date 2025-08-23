"""
RSS LLM Service Native v3.0
Optimisé avec llama.cpp local
"""

from flask import Flask, request, jsonify
import json
import time
import logging
from pathlib import Path
from llama_client import LlamaClient

# Configuration logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Chargement configuration
def load_config():
    config_path = Path("../config/sources.json")
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Erreur chargement config: {e}")
        return {}

config = load_config()
llama_client = LlamaClient(config.get('llama_config', {}))

@app.route('/generate_metadata', methods=['POST'])
def generate_metadata():
    """Endpoint principal - Classification + métadonnées avec hashtags Obsidian"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        start_time = time.time()
        
        # 1. Classification avec llama.cpp
        domains_config = config.get('domains', {})
        available_domains = list(domains_config.keys())
        
        classification = llama_client.classify_domain(title, content, available_domains)
        domain = classification['domain']
        
        # 2. Informations du domaine
        domain_info = domains_config.get(domain, {})
        
        # 3. Génération tags et alertes (logique améliorée)
        alert_level = determine_alert_level(title, content, domain)
        tags = generate_tags_with_hashtags(title, content, domain)  # 🔧 NOUVELLE FONCTION
        concepts = extract_concepts_with_hashtags(title, content, domain)  # 🔧 NOUVELLE FONCTION
        
        total_time = time.time() - start_time
        
        result = {
            "domain": domain,
            "domain_label": domain_info.get('label', domain),
            "domain_emoji": domain_info.get('emoji', '📄'),
            "confidence": classification['confidence'],
            "classification_method": classification['method'],
            "alert_level": alert_level,
            "tags": tags,  # 🏷️ AVEC HASHTAGS
            "obsidian_concepts": concepts,  # 🏷️ AVEC HASHTAGS
            "obsidian_tags": generate_obsidian_tags(domain, alert_level, tags),  # 🔧 NOUVEAU
            "output_folder": domain_info.get('output_folder', domain),
            "processing_time": total_time,
            "llm_used": classification['method'].startswith('llama'),
            "version": "3.1_native_llama_enhanced"
        }
        
        logger.info(f"✅ Classification: {domain} ({classification['confidence']}%) avec hashtags")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erreur generate_metadata: {e}")
        return jsonify({"error": str(e)}), 500

def generate_tags_with_hashtags(title: str, content: str, domain: str) -> list:
    """Génère des tags avec hashtags Obsidian"""
    tags = []
    
    # Tag principal du domaine
    domain_tag = f"#{domain.replace('_', '-')}"
    tags.append(domain_tag)
    
    text = (title + " " + content).lower()
    
    # Tags contextuels avec hashtags
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
        'russia': '#russie',
        'ukraine': '#ukraine'
    }
    
    for geo, hashtag in geo_mapping.items():
        if geo in text:
            tags.append(hashtag)
            
    return list(set(tags))  # Supprimer doublons

def extract_concepts_with_hashtags(title: str, content: str, domain: str) -> list:
    """Extrait des concepts Obsidian avec liens"""
    concepts = []
    
    # Concepts de base par domaine avec hashtags
    domain_concepts = {
        'fraude_investissement': ['#Fraude-Financière', '#Protection-Investisseurs', '#AMF', '#Ponzi-Scheme'],
        'fraude_paiement': ['#Sécurité-Bancaire', '#Moyens-de-Paiement', '#PCI-DSS', '#Card-Skimming'],
        'cyber_investigations': ['#Cybersécurité', '#Investigation-Numérique', '#Forensic', '#CERT'],
        'fraude_crypto': ['#Cryptomonnaies', '#Blockchain-Security', '#DeFi-Risks', '#Rug-Pull'],
        'supply_chain_cyber': ['#Supply-Chain', '#Third-Party-Risk', '#Vendor-Security'],
        'fraude_president_cyber': ['#FOVI', '#CEO-Fraud', '#Business-Email-Compromise', '#Social-Engineering'],
        'fraude_ecommerce': ['#E-commerce-Security', '#Online-Fraud', '#Payment-Security']
    }
    
    base_concepts = domain_concepts.get(domain, ['#Cybersécurité', '#Veille-Technologique'])
    concepts.extend(base_concepts)
    
    # Extraction d'entités avec hashtags
    text = (title + " " + content).lower()
    
    # Organisations/Entreprises
    orgs = ['microsoft', 'google', 'apple', 'amazon', 'paypal', 'visa', 'mastercard']
    for org in orgs:
        if org in text:
            concepts.append(f"#{org.title()}")
    
    # Technologies
    tech = ['windows', 'linux', 'android', 'ios', 'chrome', 'firefox', 'outlook']
    for tech_item in tech:
        if tech_item in text:
            concepts.append(f"#{tech_item.title()}")
            
    return list(set(concepts))

def generate_obsidian_tags(domain: str, alert_level: str, tags: list) -> str:
    """Génère une chaîne de tags Obsidian formatée"""
    all_tags = [f"#{domain.replace('_', '-')}", f"#{alert_level}"] + tags
    return ' '.join(list(set(all_tags)))  # Supprimer doublons

@app.route('/summarize', methods=['POST'])
def summarize():
    """Génération de résumé avec llama.cpp"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        domain = data.get('domain', 'cyber_investigations')
        
        summary_result = llama_client.generate_summary(title, content, domain)
        
        return jsonify({
            "summary": summary_result['summary'],
            "domain": domain,
            "processing_time": summary_result['processing_time'],
            "method": summary_result['method'],
            "version": "3.0_native"
        })
        
    except Exception as e:
        logger.error(f"Erreur summarize: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check avec status llama.cpp"""
    try:
        llama_status = llama_client.health_check()
        
        return jsonify({
            "status": "ok",
            "service": "RSS LLM Service v3.0 Native", 
            "llama_servers": llama_status,
            "models": {
                "classification": "tinyllama-1.1b-q4.gguf",
                "summary": "qwen2-0.5b-q4.gguf"
            },
            "version": "3.0_native_llama"
        })
        
    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 500

def determine_alert_level(title: str, content: str, domain: str) -> str:
    """Détermine le niveau d'alerte"""
    text = (title + " " + content).lower()
    
    if any(word in text for word in ['breach', 'attack', 'urgent', 'critical']):
        return 'urgent'
    elif any(word in text for word in ['warning', 'risk', 'threat']):
        return 'watch'
    else:
        return 'info'

def generate_tags(title: str, content: str, domain: str) -> list:
    """Génère des tags basiques"""
    tags = [domain.replace('_', '-')]
    
    text = (title + " " + content).lower()
    if 'urgent' in text or 'critical' in text:
        tags.append('urgent')
    if 'fraud' in text or 'fraude' in text:
        tags.append('fraud-alert')
        
    return tags

def extract_concepts(title: str, content: str, domain: str) -> list:
    """Extrait des concepts Obsidian"""
    domain_concepts = {
        'fraude_investissement': ['Fraude Financière', 'Protection Investisseurs'],
        'fraude_paiement': ['Sécurité Bancaire', 'Moyens de Paiement'],
        'cyber_investigations': ['Cybersécurité', 'Investigation Numérique'],
        'fraude_crypto': ['Cryptomonnaies', 'Blockchain Security']
    }
    
    return domain_concepts.get(domain, ['Cybersécurité', 'Veille Technologique'])

if __name__ == '__main__':
    logger.info("🚀 Démarrage RSS LLM Service Native v3.0")
    app.run(host='0.0.0.0', port=15000, debug=False)
