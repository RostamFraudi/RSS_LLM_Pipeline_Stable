from flask import Flask, request, jsonify
import json
import os
import logging
import time
import re
from pathlib import Path

# Imports pour LLM réel
try:
    from transformers import pipeline, AutoModelForSequenceClassification, AutoTokenizer
    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False
    logging.warning("⚠️ Transformers non disponible - Mode fallback uniquement")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Variables globales pour les modèles
classifier = None
summarizer = None
model_loaded = False

# ==================== CONFIGURATION ====================

class ConfigManager:
    """Gestionnaire de configuration centralisé"""
    
    def __init__(self, config_path="/config"):
        self.config_path = Path(config_path)
        self.domains_config = {}
        self.sources_config = []
        self.prompts_config = {}
        self.load_configuration()
    
    def load_configuration(self):
        """Charge la configuration depuis les fichiers JSON"""
        try:
            # Charger sources.json
            sources_file = self.config_path / "sources.json"
            if sources_file.exists():
                with open(sources_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.domains_config = config.get('domains', {})
                    self.sources_config = config.get('sources', [])
            
            # Charger prompts.json
            prompts_file = self.config_path / "prompts.json"
            if prompts_file.exists():
                with open(prompts_file, 'r', encoding='utf-8') as f:
                    self.prompts_config = json.load(f)
            
            logger.info(f"✅ Configuration chargée: {len(self.domains_config)} domaines")
            
        except Exception as e:
            logger.error(f"❌ Erreur chargement configuration: {e}")
            self._load_default_config()
    
    def _load_default_config(self):
        """Configuration par défaut minimale"""
        logger.warning("🔄 Chargement configuration par défaut")
        self.domains_config = {
            'cyber_investigations': {
                'label': 'Cyber Investigations',
                'description': 'General cybercrime and security investigations',
                'keywords': ['cyber', 'security', 'breach', 'hack']
            }
        }

# Instance globale de configuration
config = ConfigManager()

# ==================== MODÈLES LLM ====================

def load_models():
    """Charge les modèles LLM pour classification et résumé"""
    global classifier, summarizer, model_loaded
    
    if not TRANSFORMERS_AVAILABLE:
        logger.warning("⚠️ Transformers non disponible - Utilisation du mode fallback")
        return False
    
    try:
        logger.info("🔄 Chargement des modèles LLM...")
        
        # Modèle de classification zero-shot (léger et efficace)
        logger.info("📊 Chargement du classificateur zero-shot...")
        classifier = pipeline(
            "zero-shot-classification",
            model="MoritzLaurer/DeBERTa-v3-base-mnli-fever-anli",
            device=-1  # CPU pour éviter les problèmes CUDA
        )
        logger.info("✅ Classificateur chargé")
        
        # Modèle de résumé (léger)
        logger.info("📝 Chargement du modèle de résumé...")
        summarizer = pipeline(
            "summarization",
            model="sshleifer/distilbart-cnn-12-6",
            device=-1,
            max_length=150,
            min_length=50
        )
        logger.info("✅ Modèle de résumé chargé")
        
        model_loaded = True
        logger.info("✅ Tous les modèles LLM sont chargés et prêts")
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur chargement modèles: {e}")
        logger.warning("⚠️ Basculement en mode fallback")
        model_loaded = False
        return False

# ==================== GÉNÉRATION DE TAGS ====================

def generate_tags(title, content, domain, confidence):
    """
    Génère des tags intelligents en anglais
    Retourne: liste de tags sans doublons
    """
    tags = set()  # Utiliser un set pour éviter les doublons
    
    # Tags de base par domaine (en anglais)
    domain_base_tags = {
        'fraude_investissement': ['investment-fraud', 'scam-alert'],
        'fraude_paiement': ['payment-security', 'card-fraud'],
        'fraude_president_cyber': ['ceo-fraud', 'wire-fraud'],
        'fraude_ecommerce': ['ecommerce-fraud', 'online-scam'],
        'supply_chain_cyber': ['supply-chain', 'third-party-risk'],
        'intelligence_economique': ['business-intel', 'risk-analysis'],
        'fraude_crypto': ['crypto-fraud', 'blockchain-scam'],
        'cyber_investigations': ['cybercrime', 'investigation']
    }
    
    # Ajouter tags de base du domaine
    if domain in domain_base_tags:
        tags.update(domain_base_tags[domain])
    
    # Tags basés sur le niveau de confiance
    if confidence >= 90:
        tags.add('high-confidence')
    elif confidence >= 70:
        tags.add('medium-confidence')
    
    # Analyse contextuelle pour tags spécifiques
    text_lower = (title + " " + content).lower()
    
    # Tags d'urgence
    if any(word in text_lower for word in ['urgent', 'critical', 'immediate', 'breach', 'attack']):
        tags.add('urgent')
    
    # Tags techniques spécifiques
    if 'ransomware' in text_lower:
        tags.add('ransomware')
    if 'phishing' in text_lower:
        tags.add('phishing')
    if 'data breach' in text_lower or 'data leak' in text_lower:
        tags.add('data-breach')
    if 'zero-day' in text_lower or 'zero day' in text_lower:
        tags.add('zero-day')
    
    # Tags business
    if any(word in text_lower for word in ['ipo', 'acquisition', 'merger']):
        tags.add('business-event')
    if any(word in text_lower for word in ['funding', 'investment round', 'series']):
        tags.add('funding')
    
    # Limiter à 6 tags maximum et convertir en liste
    return list(tags)[:6]

def determine_alert_level(title, content, domain, confidence):
    """
    Détermine le niveau d'alerte basé sur le contenu
    Retourne: 'critical', 'urgent', 'watch', 'info'
    """
    text_lower = (title + " " + content).lower()
    
    # Mots-clés critiques
    critical_keywords = [
        'breach', 'attack', 'hacked', 'stolen', 'leaked', 'ransomware',
        'zero-day', 'critical vulnerability', 'emergency'
    ]
    
    # Mots-clés urgents
    urgent_keywords = [
        'warning', 'alert', 'risk', 'threat', 'vulnerability',
        'suspicious', 'malware', 'phishing'
    ]
    
    # Domaines naturellement urgents
    urgent_domains = ['fraude_paiement', 'fraude_president_cyber']
    
    # Analyse
    if any(keyword in text_lower for keyword in critical_keywords):
        return 'critical'
    
    if any(keyword in text_lower for keyword in urgent_keywords) or domain in urgent_domains:
        return 'urgent'
    
    if confidence >= 80 and domain in ['fraude_investissement', 'fraude_crypto']:
        return 'watch'
    
    return 'info'

# ==================== CLASSIFICATION PRINCIPALE ====================

def classify(title, content, source=""):
    """
    Fonction principale de classification - Utilise LLM si disponible
    Retourne: (domain, confidence, method)
    """
    if model_loaded and TRANSFORMERS_AVAILABLE:
        # TODO: Implémenter classification LLM
        return classify_with_llm(title, content, source)
    else:
        # Fallback vers l'ancienne méthode
        return classify_fallback(title, content, source)

def classify_with_llm(title, content, source):
    """Classification utilisant un vrai LLM"""
    try:
        # Préparation du texte pour le LLM
        text_to_classify = f"{title}. {content[:1000]}"  # Limite pour performance
        
        # Définition des catégories pour le modèle zero-shot
        candidate_labels = [
            "investment fraud and scams",
            "payment and credit card fraud",
            "CEO fraud and wire transfer scams",
            "e-commerce and online shopping fraud",
            "supply chain cyber attacks",
            "economic intelligence and business risks",
            "cryptocurrency fraud and scams",
            "cybercrime investigation and security breaches"
        ]
        
        # Mapping vers nos domaines
        label_to_domain = {
            "investment fraud and scams": "fraude_investissement",
            "payment and credit card fraud": "fraude_paiement",
            "CEO fraud and wire transfer scams": "fraude_president_cyber",
            "e-commerce and online shopping fraud": "fraude_ecommerce",
            "supply chain cyber attacks": "supply_chain_cyber",
            "economic intelligence and business risks": "intelligence_economique",
            "cryptocurrency fraud and scams": "fraude_crypto",
            "cybercrime investigation and security breaches": "cyber_investigations"
        }
        
        # Classification par le LLM
        logger.info(f"🤖 Classification LLM pour: {title[:50]}...")
        result = classifier(text_to_classify, candidate_labels, multi_label=False)
        
        # Extraction des résultats
        best_label = result['labels'][0]
        confidence = round(result['scores'][0] * 100, 1)
        
        # Mapping vers notre domaine
        domain = label_to_domain.get(best_label, "cyber_investigations")
        
        logger.info(f"✅ LLM: {domain} ({confidence}%) - Label: {best_label}")
        
        # Boost de confiance si la source correspond
        source_lower = source.lower()
        if ("amf" in source_lower and domain == "fraude_investissement") or \
           ("krebs" in source_lower and domain == "cyber_investigations") or \
           ("coindesk" in source_lower and domain == "fraude_crypto"):
            confidence = min(95, confidence + 10)
            logger.info(f"🎯 Boost source: {confidence}%")
        
        return domain, confidence, "llm_zero_shot"
        
    except Exception as e:
        logger.error(f"❌ Erreur classification LLM: {e}")
        logger.warning("🔄 Fallback vers classification par règles")
        return classify_fallback(title, content, source)

def classify_fallback(title, content, source):
    """Classification par règles (ancienne méthode v2)"""
    text = (title + " " + content + " " + source).lower()
    domain_scores = {}
    
    # Logique de l'ancienne v2
    for domain_id, domain_config in config.domains_config.items():
        score = 0
        keywords = domain_config.get('keywords', [])
        
        for keyword in keywords:
            if keyword.lower() in text:
                score += 1
        
        domain_scores[domain_id] = score
    
    # Déterminer le meilleur domaine
    if domain_scores and max(domain_scores.values()) > 0:
        best_domain = max(domain_scores, key=domain_scores.get)
        confidence = min(95, max(50, domain_scores[best_domain] * 20))
        method = "fallback"
    else:
        best_domain = 'cyber_investigations'
        confidence = 40
        method = "fallback_default"
    
    logger.info(f"📊 Classification fallback: {best_domain} ({confidence}%)")
    return best_domain, confidence, method

# ==================== ENDPOINTS API ====================

@app.route('/generate_metadata', methods=['POST'])
def generate_metadata():
    """
    Endpoint unifié principal - Classification + Tags + Alertes
    Remplace l'ancien generate_metadata de la v2
    """
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        start_time = time.time()
        
        # 1. Classification
        domain, confidence, method = classify(title, content, source)
        
        # 2. Niveau d'alerte
        alert_level = determine_alert_level(title, content, domain, confidence)
        
        # 3. Génération des tags
        tags = generate_tags(title, content, domain, confidence)
        
        # 4. Informations du domaine
        domain_info = config.domains_config.get(domain, {})
        
        # 5. Concepts Obsidian (pour compatibilité)
        obsidian_concepts = extract_obsidian_concepts(title, content, domain)
        
        duration = time.time() - start_time
        
        result = {
            # Classification
            "domain": domain,
            "domain_label": domain_info.get('label', domain.replace('_', ' ').title()),
            "confidence": confidence,
            "classification_method": method,
            
            # Alertes et tags
            "alert_level": alert_level,
            "tags": tags,
            "obsidian_concepts": obsidian_concepts,
            
            # Métadonnées
            "output_folder": domain.replace('_', '-'),
            "processing_time": duration,
            "llm_used": method.startswith('llm'),
            "version": "3.0_hybrid"
        }
        
        logger.info(f"✅ Métadonnées générées: {domain} ({confidence}%) - {alert_level} - {len(tags)} tags")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ Erreur génération métadonnées: {e}")
        return jsonify({
            "error": str(e),
            "domain": "cyber_investigations",
            "confidence": 0,
            "alert_level": "info",
            "tags": [],
            "version": "3.0_error"
        }), 500

def extract_obsidian_concepts(title, content, domain):
    """
    Extrait des concepts pour liens Obsidian
    TODO: Utiliser LLM pour extraction intelligente
    """
    # Pour l'instant, concepts prédéfinis par domaine
    domain_concepts = {
        'fraude_investissement': ['Investment Fraud', 'Financial Security', 'Scam Prevention'],
        'fraude_paiement': ['Payment Security', 'Card Fraud', 'Transaction Monitoring'],
        'fraude_president_cyber': ['CEO Fraud', 'Social Engineering', 'Wire Transfer Security'],
        'fraude_ecommerce': ['E-commerce Security', 'Online Fraud', 'Customer Protection'],
        'supply_chain_cyber': ['Supply Chain Security', 'Third Party Risk', 'Vendor Management'],
        'intelligence_economique': ['Business Intelligence', 'Risk Assessment', 'Market Analysis'],
        'fraude_crypto': ['Cryptocurrency', 'Blockchain Security', 'Digital Assets'],
        'cyber_investigations': ['Cybercrime', 'Digital Forensics', 'Threat Intelligence']
    }
    
    concepts = domain_concepts.get(domain, ['Cybersecurity', 'Risk Management'])
    return concepts[:3]  # Maximum 3 concepts

@app.route('/classify', methods=['POST'])
def classify_endpoint():
    """
    Endpoint de classification simple (pour compatibilité)
    Utilise generate_metadata en interne
    """
    result = generate_metadata()
    if isinstance(result, tuple):  # Si erreur
        return result
    
    # Extraire seulement les infos de classification
    response_data = result.get_json()
    return jsonify({
        "domain": response_data["domain"],
        "confidence": response_data["confidence"],
        "method": response_data["classification_method"],
        "alert_level": response_data["alert_level"],
        "tags": response_data["tags"]
    })

@app.route('/summarize', methods=['POST'])
def summarize_endpoint():
    """Endpoint de génération de résumé"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        domain = data.get('domain', 'cyber_investigations')
        
        start_time = time.time()
        
        # Générer le résumé
        summary = generate_summary(title, content, domain)
        
        duration = time.time() - start_time
        
        return jsonify({
            "summary": summary,
            "domain": domain,
            "processing_time": duration,
            "method": "llm" if model_loaded else "template",
            "version": "3.0"
        })
        
    except Exception as e:
        logger.error(f"❌ Erreur résumé: {e}")
        return jsonify({
            "error": str(e),
            "summary": f"**{title}**\n\nErreur lors de la génération du résumé."
        }), 500

def generate_summary(title, content, domain):
    """
    Génère un résumé intelligent
    Utilise le LLM si disponible, sinon template
    """
    if model_loaded and summarizer:
        try:
            # Résumé par LLM
            text_to_summarize = f"{title}. {content[:2000]}"
            result = summarizer(text_to_summarize, max_length=150, min_length=50)
            summary = result[0]['summary_text']
            
            # Formater pour le domaine
            domain_labels = {
                'fraude_investissement': '💰 **Investment Fraud Alert**',
                'fraude_paiement': '💳 **Payment Security Alert**',
                'fraude_president_cyber': '🎭 **CEO Fraud Warning**',
                'fraude_ecommerce': '🛒 **E-commerce Fraud Alert**',
                'supply_chain_cyber': '🔗 **Supply Chain Risk**',
                'intelligence_economique': '🕵️ **Business Intelligence**',
                'fraude_crypto': '₿ **Crypto Fraud Alert**',
                'cyber_investigations': '🔍 **Cybercrime Investigation**'
            }
            
            label = domain_labels.get(domain, '📊 **Security Alert**')
            
            return f"{label}: {title}\n\n{summary}"
            
        except Exception as e:
            logger.error(f"Erreur LLM summary: {e}")
            # Fallback vers template
    
    # Template de résumé par défaut
    return generate_summary_template(title, content, domain)

def generate_summary_template(title, content, domain):
    """
    Génère un résumé basé sur un template (fallback)
    """
    # Extraire première phrase significative
    sentences = [s.strip() for s in content.split('.') if len(s.strip()) > 20]
    first_sentence = sentences[0] if sentences else "Details in article"
    
    templates = {
        'fraude_investissement': "💰 **Investment Fraud Alert**: {title}\n\n• **Threat**: {sentence}\n• **Target**: Investors and savers\n• **Action**: Verify with financial authorities",
        'fraude_paiement': "💳 **Payment Security Alert**: {title}\n\n• **Risk**: {sentence}\n• **Impact**: Financial loss potential\n• **Protection**: Monitor transactions closely",
        'fraude_president_cyber': "🎭 **CEO Fraud Warning**: {title}\n\n• **Method**: {sentence}\n• **Target**: Corporate executives\n• **Prevention**: Verify all wire transfer requests",
        'default': "🔍 **Security Alert**: {title}\n\n• **Summary**: {sentence}\n• **Category**: {domain}\n• **Action**: Review and assess impact"
    }
    
    template = templates.get(domain, templates['default'])
    return template.format(title=title, sentence=first_sentence, domain=domain.replace('_', ' ').title())

# Alias pour compatibilité avec v2
@app.route('/summarize_v2', methods=['POST'])
def summarize_v2_endpoint():
    """Alias pour compatibilité avec l'ancienne API"""
    return summarize_endpoint()

@app.route('/classify_v2', methods=['POST'])
def classify_v2_endpoint():
    """Alias pour compatibilité avec l'ancienne API"""
    return generate_metadata()

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "ok",
        "service": "RSS LLM Service v3.0",
        "llm_loaded": model_loaded,
        "transformers_available": TRANSFORMERS_AVAILABLE,
        "domains_count": len(config.domains_config),
        "version": "3.0_hybrid"
    })

@app.route('/status', methods=['GET'])
def status():
    """Status détaillé du service"""
    return jsonify({
        "service": "RSS LLM Service v3.0 - Hybrid Architecture",
        "architecture": "LLM + Fallback Rules",
        "models": {
            "classifier": "DeBERTa-v3-base-mnli" if model_loaded else "Not loaded",
            "summarizer": "distilbart-cnn-12-6" if model_loaded else "Not loaded",
            "status": "operational" if model_loaded else "fallback_mode"
        },
        "endpoints": {
            "primary": ["/generate_metadata", "/classify", "/summarize"],
            "compatibility": ["/classify_v2", "/summarize_v2"],
            "monitoring": ["/health", "/status", "/config/info"]
        },
        "capabilities": {
            "classification": "8 fraud categories + general",
            "tags": "English, deduplicated, contextual",
            "alerts": "4 levels (critical, urgent, watch, info)",
            "summaries": "LLM-generated or template-based"
        },
        "performance": {
            "classification_avg": "0.3s" if model_loaded else "0.1s",
            "summary_avg": "1.2s" if model_loaded else "0.05s"
        },
        "version": "3.0_hybrid",
        "timestamp": time.time()
    })

@app.route('/config/info', methods=['GET'])
def config_info():
    """Informations sur la configuration actuelle"""
    return jsonify({
        "domains": list(config.domains_config.keys()),
        "sources_count": len(config.sources_config),
        "classification_method": "hybrid" if model_loaded else "rules_only",
        "supported_languages": ["en", "fr"],
        "tag_language": "en",
        "max_tags_per_article": 6,
        "alert_levels": ["critical", "urgent", "watch", "info"],
        "version": "3.0"
    })

@app.route('/reload_config', methods=['POST'])
def reload_config():
    """Recharge la configuration sans redémarrer"""
    try:
        global config
        config = ConfigManager()
        
        return jsonify({
            "status": "success",
            "message": "Configuration reloaded",
            "domains_count": len(config.domains_config),
            "sources_count": len(config.sources_config),
            "timestamp": time.time()
        })
    except Exception as e:
        logger.error(f"❌ Erreur rechargement config: {e}")
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 500

# ==================== DÉMARRAGE ====================

if __name__ == '__main__':
    logger.info("🚀 Démarrage RSS LLM Service v3.0 - Architecture Hybride")
    
    # Chargement configuration
    config = ConfigManager()
    
    # Chargement modèles LLM
    load_models()
    
    # Démarrage serveur
    app.run(host='0.0.0.0', port=5000, debug=False)
