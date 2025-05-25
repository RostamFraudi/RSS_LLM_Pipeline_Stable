from flask import Flask, request, jsonify
import json
import os
import logging
import time
import re
from pathlib import Path

# Transformers optionnel
try:
    from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False
    
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
model = None
tokenizer = None
classifier = None
summarizer = None
model_loaded = False

# ==================== CONFIGURATION LOADER ====================

class AntifraudConfigLoader:
    """Gestionnaire de configuration spécialisé Anti-Fraude"""
    
    def __init__(self, config_path="/config"):
        self.config_path = Path(config_path)
        self.domains_config = {}
        self.sources_config = []
        self.prompts_config = {}
        self.processing_config = {}
        self.classification_rules = {}
        self.alert_levels = {}
        self.load_configuration()
    
    def load_configuration(self):
        """Charge la configuration complète"""
        try:
            # Charger sources.json (domaines + sources + règles)
            sources_file = self.config_path / "sources.json"
            if sources_file.exists():
                with open(sources_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.domains_config = config.get('domains', {})
                    self.sources_config = config.get('sources', [])
                    self.processing_config = config.get('processing', {})
                    self.classification_rules = config.get('classification_rules', {})
                    self.alert_levels = config.get('alert_levels', {})
            
            # Charger prompts.json
            prompts_file = self.config_path / "prompts.json"
            if prompts_file.exists():
                with open(prompts_file, 'r', encoding='utf-8') as f:
                    self.prompts_config = json.load(f)
            
            logger.info(f"✅ Configuration chargée: {len(self.domains_config)} domaines, {len(self.sources_config)} sources")
            
        except Exception as e:
            logger.error(f"❌ Erreur chargement configuration: {e}")
            self._load_fallback_config()
    
    def _load_fallback_config(self):
        """Configuration minimale en cas d'erreur"""
        logger.warning("🔄 Chargement configuration fallback")
        self.domains_config = {
            'cyber_investigations': {
                'label': 'Investigations Cybercriminalité',
                'emoji': '🔍',
                'default_alert': 'info',
                'critical_keywords': ['cybercrime', 'investigation', 'fraud'],
                'output_folder': 'cyber_investigations'
            }
        }
    
    def classify_article(self, title, content, source=""):
        """Classification intelligente basée sur la configuration"""
        text = (title + " " + content + " " + source).lower()
        
        # Scores par domaine
        domain_scores = {}
        
        for domain_id, domain_config in self.domains_config.items():
            score = 0
            
            # Score basé sur les mots-clés critiques
            critical_keywords = domain_config.get('critical_keywords', [])
            for keyword in critical_keywords:
                if keyword.lower() in text:
                    score += 2  # Poids fort pour mots-clés critiques
            
            # Score basé sur les mots-clés d'alerte
            alert_keywords = domain_config.get('alert_keywords', [])
            for keyword in alert_keywords:
                if keyword.lower() in text:
                    score += 1  # Poids moyen pour mots-clés d'alerte
            
            # Bonus basé sur la source
            source_bonus = self._get_source_bonus(source.lower(), domain_id)
            score += source_bonus
            
            # Multiplicateur de priorité du domaine
            priority_mult = domain_config.get('priority_multiplier', 1.0)
            score *= priority_mult
            
            domain_scores[domain_id] = score
        
        # Déterminer le meilleur domaine
        if max(domain_scores.values(), default=0) > 0:
            best_domain = max(domain_scores, key=domain_scores.get)
            confidence = min(95, max(60, domain_scores[best_domain] * 15))
        else:
            # Fallback vers domaine par défaut
            fallback_domain = self.classification_rules.get('confidence_thresholds', {}).get('fallback_domain', 'cyber_investigations')
            best_domain = fallback_domain if fallback_domain in self.domains_config else list(self.domains_config.keys())[0]
            confidence = 50
        
        return best_domain, confidence
    
    def _get_source_bonus(self, source_lower, domain_id):
        """Calcule le bonus basé sur la source"""
        source_rules = self.classification_rules.get('source_bonus', {}).get('rules', {})
        
        for source_key, rule in source_rules.items():
            if source_key.lower() in source_lower and rule.get('domain') == domain_id:
                return rule.get('bonus', 0)
        
        return 0
    
    def get_alert_level(self, title, content, domain_id):
        """Détermine le niveau d'alerte"""
        text = (title + " " + content).lower()
        domain_config = self.domains_config.get(domain_id, {})
        
        # Mots-clés critiques du domaine
        critical_keywords = domain_config.get('critical_keywords', [])
        alert_keywords = domain_config.get('alert_keywords', [])
        
        # Vérification mots-clés critiques universels
        universal_critical = ['breach', 'attack', 'critical', 'urgent', 'hack', 'stolen', 'leaked', 'compromise']
        if any(keyword.lower() in text for keyword in critical_keywords + universal_critical):
            return "critical"
        
        # Vérification mots-clés d'alerte
        universal_alert = ['warning', 'risk', 'threat', 'concern', 'issue', 'problem', 'vulnerability']
        if any(keyword.lower() in text for keyword in alert_keywords + universal_alert):
            return "urgent"
        
        # Niveau par défaut du domaine
        return domain_config.get('default_alert', 'info')
    
    def generate_obsidian_concepts(self, title, content, domain_id):
        """Génère des concepts Obsidian basés sur la configuration"""
        domain_config = self.domains_config.get(domain_id, {})
        concepts = []
        
        # Concepts prédéfinis du domaine
        predefined_concepts = domain_config.get('obsidian_concepts', [])
        
        # Ajouter concepts basés sur les mots-clés trouvés
        text = (title + " " + content).lower()
        critical_keywords = domain_config.get('critical_keywords', [])
        
        # Concepts du domaine (max 2)
        concepts.extend(predefined_concepts[:2])
        
        # Concepts basés sur mots-clés trouvés (max 2 additionnels)
        for keyword in critical_keywords[:4]:
            if keyword.lower() in text:
                concept = keyword.replace('_', ' ').title()
                if concept not in concepts and len(concepts) < 4:
                    concepts.append(concept)
        
        return concepts[:4]  # Maximum 4 concepts
    
    def generate_strategic_tags(self, title, content, domain_id, alert_level):
        """Génère des tags stratégiques"""
        tags = []
        
        # Tags basés sur le niveau d'alerte
        if alert_level == "critical":
            tags.append("#urgent")
            tags.append("#critical-alert")
        elif alert_level == "urgent":
            tags.append("#important")
            tags.append("#urgent-review")
        elif alert_level == "watch":
            tags.append("#monitoring")
        
        # Tag du domaine
        domain_tag = f"#{domain_id.replace('_', '-')}"
        tags.append(domain_tag)
        
        # Tags contextuels basés sur le contenu
        text = (title + " " + content).lower()
        if any(word in text for word in ['fraud', 'fraude', 'scam', 'arnaque']):
            tags.append("#fraud-alert")
        if any(word in text for word in ['crypto', 'bitcoin', 'blockchain']):
            tags.append("#crypto")
        if any(word in text for word in ['payment', 'paiement', 'carte', 'virement']):
            tags.append("#payment-security")
        
        return tags[:6]  # Maximum 6 tags
    
    def generate_summary(self, title, content, domain_id):
        """Génère un résumé adapté au domaine"""
        domain_config = self.domains_config.get(domain_id, {})
        emoji = domain_config.get('emoji', '📄')
        label = domain_config.get('label', domain_id.replace('_', ' ').title())
        
        # Extraire première phrase significative
        sentences = [s.strip() for s in content.split('.') if len(s.strip()) > 20]
        main_point = sentences[0] if sentences else "Analyse en cours"
        
        # Template adapté au domaine
        if domain_id in ['fraude_investissement', 'fraude_crypto']:
            summary = f"""{emoji} **{label}** : {title}

• **Mécanisme** : {main_point}
• **Cibles** : Investisseurs et épargnants
• **Prévention** : Vigilance et vérification AMF
• **Action** : Surveillance renforcée des offres"""

        elif domain_id in ['fraude_paiement', 'fraude_president_cyber']:
            summary = f"""{emoji} **{label}** : {title}

• **Technique** : {main_point}
• **Impact** : Risque financier direct
• **Détection** : Signaux d'alerte à identifier
• **Mitigation** : Mesures de protection immédiates"""

        elif domain_id in ['cyber_investigations', 'supply_chain_cyber']:
            summary = f"""{emoji} **{label}** : {title}

• **Analyse** : {main_point}
• **Portée** : Investigation en cours
• **Implications** : Évaluation des risques
• **Suivi** : Veille continue nécessaire"""

        else:  # Domaines généraux
            summary = f"""{emoji} **{label}** : {title}

• **Contexte** : {main_point}
• **Enjeux** : Analyse sectorielle
• **Recommandation** : Monitoring continu
• **Classification** : {domain_id}"""
        
        return summary

# Instance globale
config = AntifraudConfigLoader()

def load_model():
    """Charge les modèles Transformers (optionnel)"""
    global model, tokenizer, classifier, summarizer, model_loaded
    
    if not TRANSFORMERS_AVAILABLE:
        logger.info("ℹ️  Transformers non disponible - Mode configuration pure")
        model_loaded = False
        return False
        
    try:
        logger.info("🔄 Chargement modèles légers...")
        
        # Classification sentiments (léger)
        classifier = pipeline("sentiment-analysis")
        
        # Résumé (optionnel)
        try:
            summarizer = pipeline(
                "summarization",
                model="facebook/bart-large-cnn",
                max_length=150,
                min_length=30,
                do_sample=False
            )
        except:
            logger.warning("⚠️  Modèle résumé non disponible")
        
        model_loaded = True
        logger.info("✅ Modèles chargés avec succès!")
        return True
        
    except Exception as e:
        logger.warning(f"⚠️  Modèles non chargés: {e}")
        model_loaded = False
        return False

# ==================== ENDPOINTS V2 CONFIGURABLES ====================

@app.route('/classify_v2', methods=['POST'])
def classify_v2():
    """Classification intelligente v2.0 - Configuré par sources.json"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        start_time = time.time()
        
        # Classification basée sur configuration
        domain, confidence = config.classify_article(title, content, source)
        
        # Métadonnées du domaine
        domain_config = config.domains_config.get(domain, {})
        
        # Niveau d'alerte
        alert_level = config.get_alert_level(title, content, domain)
        
        # Concepts Obsidian
        obsidian_concepts = config.generate_obsidian_concepts(title, content, domain)
        
        # Tags stratégiques
        strategic_tags = config.generate_strategic_tags(title, content, domain, alert_level)
        
        duration = time.time() - start_time
        
        result = {
            "domain": domain,
            "domain_label": domain_config.get('label', domain),
            "domain_emoji": domain_config.get('emoji', '📄'),
            "confidence": confidence,
            "alert_level": alert_level,
            "obsidian_concepts": obsidian_concepts,
            "strategic_tags": strategic_tags,
            "output_folder": domain_config.get('output_folder', domain),
            "processing_time": duration,
            "version": "2.0_config_only",
            "classification_method": "configuration_based"
        }
        
        logger.info(f"✅ Classification V2: {domain} ({confidence}%) - {alert_level}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ Erreur classification V2: {e}")
        return jsonify({
            "domain": "cyber_investigations",
            "confidence": 50,
            "alert_level": "info",
            "obsidian_concepts": [],
            "strategic_tags": ["#error"],
            "error": str(e),
            "version": "2.0_fallback"
        }), 200

@app.route('/summarize_v2', methods=['POST'])
def summarize_v2():
    """Résumé intelligent v2.0 - Configuré par domaine"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        domain = data.get('domain', 'cyber_investigations')
        
        start_time = time.time()
        
        # Résumé basé sur configuration du domaine
        summary = config.generate_summary(title, content, domain)
        
        duration = time.time() - start_time
        
        logger.info(f"✅ Résumé V2 généré pour {domain} (durée: {duration:.2f}s)")
        return jsonify({
            "summary": summary,
            "domain": domain,
            "processing_time": duration,
            "version": "2.0_config_only"
        })
        
    except Exception as e:
        logger.error(f"❌ Erreur résumé V2: {e}")
        return jsonify({
            "error": str(e),
            "summary": f"**Résumé de** : {data.get('title', 'Article')}\n\n• Contenu analysé automatiquement\n• Classification effectuée"
        }), 200

@app.route('/generate_metadata', methods=['POST'])
def generate_metadata():
    """Endpoint unifié - Classification + Résumé + Métadonnées complètes"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        start_time = time.time()
        
        # Classification complète
        domain, confidence = config.classify_article(title, content, source)
        domain_config = config.domains_config.get(domain, {})
        
        # Toutes les métadonnées
        alert_level = config.get_alert_level(title, content, domain)
        obsidian_concepts = config.generate_obsidian_concepts(title, content, domain)
        strategic_tags = config.generate_strategic_tags(title, content, domain, alert_level)
        summary = config.generate_summary(title, content, domain)
        
        duration = time.time() - start_time
        
        result = {
            # Classification
            "domain": domain,
            "domain_label": domain_config.get('label', domain),
            "domain_emoji": domain_config.get('emoji', '📄'),
            "confidence": confidence,
            "alert_level": alert_level,
            
            # Métadonnées
            "obsidian_concepts": obsidian_concepts,
            "strategic_tags": strategic_tags,
            "output_folder": domain_config.get('output_folder', domain),
            
            # Contenu
            "summary": summary,
            
            # Technique
            "processing_time": duration,
            "classification_method": "unified_config_v2",
            "version": "2.0_unified"
        }
        
        logger.info(f"✅ Métadonnées unifiées: {domain} ({confidence}%) - {alert_level}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ Erreur métadonnées: {e}")
        return jsonify({"error": str(e)}), 500

# ==================== CONFIGURATION MANAGEMENT ====================

@app.route('/reload_config', methods=['POST'])
def reload_config():
    """Recharge la configuration sans redémarrer"""
    try:
        global config
        config = AntifraudConfigLoader()
        
        return jsonify({
            "status": "success",
            "message": "Configuration rechargée",
            "domains_count": len(config.domains_config),
            "domains": list(config.domains_config.keys()),
            "sources_count": len(config.sources_config),
            "timestamp": time.time()
        })
    except Exception as e:
        logger.error(f"❌ Erreur rechargement: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/config/domains', methods=['GET'])
def get_domains():
    """Liste les domaines configurés"""
    try:
        domains_info = {}
        for domain_id, domain_config in config.domains_config.items():
            domains_info[domain_id] = {
                "label": domain_config.get('label', domain_id),
                "emoji": domain_config.get('emoji', '📄'),
                "default_alert": domain_config.get('default_alert', 'info'),
                "keywords_count": len(domain_config.get('critical_keywords', [])),
                "output_folder": domain_config.get('output_folder', domain_id),
                "priority_multiplier": domain_config.get('priority_multiplier', 1.0)
            }
        
        return jsonify({
            "domains": domains_info,
            "total_count": len(domains_info),
            "version": "2.0_config_only"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/config/sources', methods=['GET'])
def get_sources():
    """Liste les sources configurées"""
    try:
        sources_by_domain = {}
        for source in config.sources_config:
            domain = source.get('domain', 'unknown')
            if domain not in sources_by_domain:
                sources_by_domain[domain] = []
            sources_by_domain[domain].append({
                "name": source.get('name'),
                "priority": source.get('priority', 'medium'),
                "keywords": source.get('keywords', [])
            })
        
        return jsonify({
            "sources_by_domain": sources_by_domain,
            "total_sources": len(config.sources_config),
            "version": "2.0_config_only"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ==================== HEALTH & STATUS ====================

@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({
        "status": "ok",
        "service": "Anti-Fraud LLM Service v2.0",
        "config_loaded": len(config.domains_config) > 0,
        "domains_count": len(config.domains_config),
        "sources_count": len(config.sources_config),
        "model_loaded": model_loaded,
        "transformers_available": TRANSFORMERS_AVAILABLE,
        "version": "2.0_config_only",
        "timestamp": time.time()
    })

@app.route('/status', methods=['GET'])
def status():
    """Statut détaillé"""
    return jsonify({
        "service": "Anti-Fraud LLM Service v2.0 - Configuration Only",
        "endpoints": [
            "/classify_v2", "/summarize_v2", "/generate_metadata",
            "/reload_config", "/config/domains", "/config/sources",
            "/health", "/status"
        ],
        "domains_available": list(config.domains_config.keys()),
        "config_status": {
            "domains_loaded": len(config.domains_config),
            "sources_loaded": len(config.sources_config),
            "prompts_loaded": len(config.prompts_config),
            "classification_rules": bool(config.classification_rules),
            "alert_levels": bool(config.alert_levels)
        },
        "model_status": {
            "transformers_available": TRANSFORMERS_AVAILABLE,
            "models_loaded": model_loaded
        },
        "version": "2.0_config_only",
        "cleaned_endpoints": "V1 endpoints removed - V2 only"
    })

if __name__ == '__main__':
    logger.info("🚀 Démarrage Anti-Fraud LLM Service v2.0 - Configuration Only")
    
    # Chargement configuration (prioritaire)
    config = AntifraudConfigLoader()
    
    # Chargement modèles (optionnel)
    load_model()
    
    # Démarrage serveur
    app.run(host='0.0.0.0', port=5000, debug=False)