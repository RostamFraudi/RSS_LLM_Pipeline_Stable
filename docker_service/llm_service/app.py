from flask import Flask, request, jsonify
import json
import os
import logging
import time
import re

# Essayons transformers standard plutôt que ctransformers
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

def load_model():
    """Charge un modèle avec transformers standard"""
    global model, tokenizer, classifier, summarizer, model_loaded
    
    if not TRANSFORMERS_AVAILABLE:
        logger.error("❌ Transformers non disponible")
        return False
        
    try:
        logger.info("🔄 Chargement modèle DistilBERT (léger et rapide)...")
        
        # Modèle de classification léger
        classifier = pipeline(
            "text-classification",
            model="distilbert-base-uncased-finetuned-sst-2-english",
            return_all_scores=True
        )
        
        # Modèle de résumé léger
        summarizer = pipeline(
            "summarization",
            model="facebook/bart-large-cnn",
            max_length=150,
            min_length=30,
            do_sample=False
        )
        
        model_loaded = True
        logger.info("✅ Modèles chargés avec succès!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur chargement modèles: {e}")
        try:
            # Fallback ultra-léger
            logger.info("🔄 Chargement modèle de secours...")
            classifier = pipeline("sentiment-analysis")
            model_loaded = True
            logger.info("✅ Modèle de secours chargé!")
            return True
        except Exception as e2:
            logger.error(f"❌ Erreur modèle de secours: {e2}")
            model_loaded = False
            return False

# ==================== CLASSIFICATION V1 (EXISTANTE) ====================

def classify_text(title, content):
    """Classification basée sur le contenu"""
    text = (title + " " + content).lower()
    
    # Mots-clés pour chaque catégorie
    keywords = {
        'ia': ['ai', 'artificial intelligence', 'machine learning', 'deep learning', 'neural', 'gpt', 'model', 'training', 'algorithm', 'llm'],
        'dev': ['api', 'code', 'programming', 'software', 'development', 'github', 'python', 'javascript', 'deployment', 'framework'],
        'business': ['business', 'partnership', 'investment', 'company', 'market', 'economic', 'revenue', 'strategy'],
        'cloud': ['cloud', 'infrastructure', 'server', 'aws', 'azure', 'docker', 'kubernetes', 'scaling', 'deployment'],
        'securite': ['security', 'safety', 'privacy', 'protection', 'secure', 'vulnerability', 'encryption']
    }
    
    # Comptage des mots-clés
    scores = {}
    for category, words in keywords.items():
        score = sum(1 for word in words if word in text)
        scores[category] = score
    
    # Catégorie avec le plus de mots-clés
    best_category = max(scores, key=scores.get) if max(scores.values()) > 0 else 'autre'
    
    # Bonus pour OpenAI (source IA)
    if 'openai' in text or scores['ia'] > 0:
        best_category = 'ia'
    
    return best_category

def summarize_text(title, content):
    """Résumé intelligent du contenu"""
    # Prendre les phrases les plus importantes
    sentences = content.split('.')[:5]  # 5 premières phrases
    
    # Créer un résumé structuré
    summary = f"""• **Sujet principal** : {title}

- **Points clés** :
  - {sentences[0].strip() if len(sentences) > 0 else 'Contenu technique'}
  - {sentences[1].strip() if len(sentences) > 1 else 'Innovation technologique'}
  - {sentences[2].strip() if len(sentences) > 2 else 'Applications pratiques'}

- **Contexte** : Article technique analysé automatiquement"""
    
    return summary

# ==================== CLASSIFICATION V2 (NOUVELLE) ====================

def classify_text_v2(title, content, source=""):
    """Classification intelligente v2.0 avec 4 domaines"""
    text = (title + " " + content + " " + source).lower()
    
    # Domaines v2.0 avec mots-clés étendus
    domains = {
        'veille_fraude': {
            'keywords': ['fraud', 'scam', 'cybersecurity', 'cyber', 'attack', 'hacking', 'breach', 'vulnerability', 
                        'malware', 'phishing', 'ransomware', 'security', 'threat', 'criminal', 'stolen', 'leak'],
            'weight': 1.0
        },
        'innovation_tech': {
            'keywords': ['ai', 'artificial intelligence', 'machine learning', 'blockchain', 'quantum', 'research',
                        'breakthrough', 'innovation', 'algorithm', 'neural', 'deep learning', 'gpt', 'llm', 'model'],
            'weight': 1.0
        },
        'finance_crypto': {
            'keywords': ['crypto', 'bitcoin', 'ethereum', 'finance', 'financial', 'bank', 'investment', 'trading',
                        'market', 'defi', 'nft', 'token', 'coin', 'exchange', 'regulation', 'fintech'],
            'weight': 1.0
        },
        'actualite_tech': {
            'keywords': ['startup', 'company', 'product', 'launch', 'acquisition', 'funding', 'venture',
                        'business', 'ceo', 'enterprise', 'partnership', 'deal', 'tech', 'technology'],
            'weight': 1.0
        }
    }
    
    # Calcul des scores
    scores = {}
    for domain, config in domains.items():
        score = sum(1 for keyword in config['keywords'] if keyword in text)
        scores[domain] = score * config['weight']
    
    # Règles contextuelles
    if 'zataz' in source.lower() or any(word in text for word in ['vulnerability', 'attack', 'breach']):
        scores['veille_fraude'] += 3
    
    if 'openai' in source.lower() or 'research' in text:
        scores['innovation_tech'] += 2
        
    if any(word in text for word in ['coindesk', 'crypto', 'bitcoin', 'defi']):
        scores['finance_crypto'] += 2
        
    if any(word in text for word in ['techcrunch', 'startup', 'funding']):
        scores['actualite_tech'] += 2
    
    # Déterminer le domaine
    best_domain = max(scores, key=scores.get) if max(scores.values()) > 0 else 'actualite_tech'
    confidence = min(90, max(60, scores[best_domain] * 15))  # Entre 60-90%
    
    return best_domain, confidence

def generate_obsidian_concepts(title, content, domain):
    """Génère des concepts pour liens Obsidian [[]]"""
    text = (title + " " + content).lower()
    
    # Concepts par domaine
    domain_concepts = {
        'veille_fraude': ['Cybersécurité', 'Fraude Financière', 'Vulnérabilités', 'Menaces Cyber'],
        'innovation_tech': ['Intelligence Artificielle', 'Blockchain', 'Machine Learning', 'Innovation Technologique'],
        'finance_crypto': ['Cryptomonnaie', 'Finance Décentralisée', 'Marchés Financiers', 'Régulation Financière'],
        'actualite_tech': ['Startups', 'Big Tech', 'Lancements Produits', 'M&A Tech']
    }
    
    # Concepts transversaux
    cross_concepts = []
    if any(word in text for word in ['ai', 'artificial intelligence', 'machine learning']):
        cross_concepts.append('Intelligence Artificielle')
    if any(word in text for word in ['blockchain', 'crypto', 'bitcoin']):
        cross_concepts.append('Blockchain')
    if any(word in text for word in ['security', 'cybersecurity', 'hack']):
        cross_concepts.append('Cybersécurité')
    
    # Combiner concepts du domaine + transversaux
    concepts = domain_concepts.get(domain, [])[:2]  # 2 concepts du domaine
    concepts.extend(cross_concepts[:2])  # + 2 concepts transversaux
    
    return list(set(concepts))  # Supprimer doublons

def generate_strategic_tags(title, content, domain, alert_level):
    """Génère des tags stratégiques"""
    text = (title + " " + content).lower()
    tags = []
    
    # Tags de base
    if alert_level == "critical":
        tags.append("#urgent")
    if alert_level == "alert":
        tags.append("#important")
        
    # Tags par domaine
    domain_tags = {
        'veille_fraude': ["#security-alert", "#threat-intel"],
        'innovation_tech': ["#innovation", "#tech-trend"],
        'finance_crypto': ["#market-trend", "#crypto-news"],
        'actualite_tech': ["#business-news", "#tech-industry"]
    }
    
    tags.extend(domain_tags.get(domain, []))
    
    # Tags contextuels
    if any(word in text for word in ['breakthrough', 'revolutionary', 'first']):
        tags.append("#breakthrough")
    if any(word in text for word in ['funding', 'investment', 'raise']):
        tags.append("#funding")
    if any(word in text for word in ['regulation', 'law', 'compliance']):
        tags.append("#regulation")
    
    return tags[:5]  # Maximum 5 tags

def determine_alert_level(title, content, domain):
    """Détermine le niveau d'alerte"""
    text = (title + " " + content).lower()
    
    # Mots-clés critiques
    critical_keywords = ['breach', 'attack', 'vulnerability', 'hack', 'stolen', 'leaked', 'critical']
    alert_keywords = ['warning', 'risk', 'threat', 'concern', 'issue', 'problem']
    
    if any(word in text for word in critical_keywords):
        return "critical"
    elif any(word in text for word in alert_keywords):
        return "alert"
    elif domain == 'veille_fraude':
        return "watch"  # Par défaut pour la sécurité
    else:
        return "info"

# ==================== ENDPOINTS V1 (EXISTANTS) ====================

@app.route('/classify', methods=['POST'])
def classify():
    """Classification d'article V1"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        
        start_time = time.time()
        
        if model_loaded and classifier:
            # Tentative avec le modèle chargé
            try:
                # Classification par mots-clés (plus fiable)
                category = classify_text(title, content)
            except:
                # Fallback
                category = classify_text(title, content)
        else:
            # Classification par mots-clés uniquement
            category = classify_text(title, content)
        
        duration = time.time() - start_time
        
        logger.info(f"✅ Classification V1: {category} (durée: {duration:.2f}s)")
        return jsonify({
            "category": category,
            "confidence": 0.9,
            "processing_time": duration,
            "version": "1.0"
        })
        
    except Exception as e:
        logger.error(f"Erreur classification V1: {e}")
        return jsonify({"error": str(e), "category": "ia"}), 500

@app.route('/summarize', methods=['POST'])
def summarize():
    """Résumé d'article V1"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        
        start_time = time.time()
        
        if model_loaded and summarizer:
            try:
                # Tentative avec le modèle de résumé
                if len(content) > 100:
                    result = summarizer(content[:1000])  # Limiter la taille
                    summary = result[0]['summary_text']
                else:
                    summary = summarize_text(title, content)
            except:
                summary = summarize_text(title, content)
        else:
            # Résumé par extraction de phrases
            summary = summarize_text(title, content)
        
        duration = time.time() - start_time
        
        logger.info(f"✅ Résumé généré V1 (durée: {duration:.2f}s)")
        return jsonify({
            "summary": summary,
            "processing_time": duration,
            "version": "1.0"
        })
        
    except Exception as e:
        logger.error(f"Erreur résumé V1: {e}")
        return jsonify({
            "error": str(e), 
            "summary": f"**Résumé de** : {data.get('title', 'Article')}\n\n• Contenu analysé automatiquement\n• Classification effectuée"
        }), 500

# ==================== ENDPOINTS V2 (NOUVEAUX) ====================

@app.route('/classify_v2', methods=['POST'])
def classify_v2():
    """Classification intelligente v2.0 avec 4 domaines"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        start_time = time.time()
        
        # Classification v2.0
        domain, confidence = classify_text_v2(title, content, source)
        
        # Niveau d'alerte
        alert_level = determine_alert_level(title, content, domain)
        
        # Génération concepts Obsidian
        obsidian_concepts = generate_obsidian_concepts(title, content, domain)
        
        # Tags stratégiques
        strategic_tags = generate_strategic_tags(title, content, domain, alert_level)
        
        duration = time.time() - start_time
        
        result = {
            "domain": domain,
            "confidence": confidence,
            "alert_level": alert_level,
            "obsidian_concepts": obsidian_concepts,
            "strategic_tags": strategic_tags,
            "processing_time": duration,
            "version": "2.0_hybrid",
            "classification_method": "intelligent_keywords"
        }
        
        logger.info(f"✅ Classification V2: {domain} ({confidence}%) - {alert_level}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erreur classification V2: {e}")
        # Fallback vers V1
        fallback = classify_text(title, content)
        return jsonify({
            "domain": fallback,
            "confidence": 70,
            "alert_level": "info",
            "obsidian_concepts": [],
            "strategic_tags": [],
            "error": "Fallback V1",
            "version": "1.0_fallback"
        }), 200

@app.route('/summarize_v2', methods=['POST'])
def summarize_v2():
    """Résumé intelligent v2.0 avec structuration"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        domain = data.get('domain', 'actualite_tech')
        
        start_time = time.time()
        
        # Résumé adapté au domaine
        if domain == 'veille_fraude':
            summary = f"🚨 **Alerte Sécurité** : {title}\n\n• **Menace** : {content.split('.')[0] if content else 'Analyse en cours'}\n• **Impact** : À évaluer\n• **Actions** : Surveillance renforcée"
        elif domain == 'innovation_tech':
            summary = f"🚀 **Innovation** : {title}\n\n• **Technologie** : {content.split('.')[0] if content else 'Développement technique'}\n• **Applications** : Potentiel élevé\n• **Suivi** : Évolution à surveiller"
        elif domain == 'finance_crypto':
            summary = f"💰 **Finance** : {title}\n\n• **Marché** : {content.split('.')[0] if content else 'Évolution financière'}\n• **Impact** : Analyse requise\n• **Recommandation** : Veille continue"
        else:  # actualite_tech
            summary = f"📱 **Tech News** : {title}\n\n• **Actualité** : {content.split('.')[0] if content else 'Développement secteur'}\n• **Secteur** : Technologie\n• **Intérêt** : Business intelligence"
        
        duration = time.time() - start_time
        
        logger.info(f"✅ Résumé V2 généré pour {domain} (durée: {duration:.2f}s)")
        return jsonify({
            "summary": summary,
            "processing_time": duration,
            "version": "2.0_structured"
        })
        
    except Exception as e:
        logger.error(f"Erreur résumé V2: {e}")
        # Fallback vers V1
        return summarize()

@app.route('/generate_metadata', methods=['POST'])
def generate_metadata():
    """Génère toutes les métadonnées d'un coup pour v2.0"""
    try:
        data = request.json
        title = data.get('title', '')
        content = data.get('content', '')
        source = data.get('source', '')
        
        start_time = time.time()
        
        # Classification complète
        domain, confidence = classify_text_v2(title, content, source)
        alert_level = determine_alert_level(title, content, domain)
        obsidian_concepts = generate_obsidian_concepts(title, content, domain)
        strategic_tags = generate_strategic_tags(title, content, domain, alert_level)
        
        # Labels pour affichage
        domain_labels = {
            'veille_fraude': 'Veille Fraude & Cybersécurité',
            'innovation_tech': 'Innovation Technologique',
            'finance_crypto': 'Finance & Crypto',
            'actualite_tech': 'Actualité Technologique'
        }
        
        duration = time.time() - start_time
        
        result = {
            "domain": domain,
            "domain_label": domain_labels.get(domain, domain),
            "confidence": confidence,
            "alert_level": alert_level,
            "obsidian_concepts": obsidian_concepts,
            "strategic_tags": strategic_tags,
            "processing_time": duration,
            "classification_method": "intelligent_v2",
            "version": "2.0_hybrid"
        }
        
        logger.info(f"✅ Métadonnées complètes générées: {domain} ({confidence}%)")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Erreur génération métadonnées: {e}")
        return jsonify({"error": str(e)}), 500

# ==================== ENDPOINTS UTILITAIRES ====================

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de santé"""
    return jsonify({
        "status": "ok",
        "model_loaded": model_loaded,
        "transformers_available": TRANSFORMERS_AVAILABLE,
        "version": "2.0_hybrid",
        "timestamp": time.time()
    })

@app.route('/status', methods=['GET'])
def status():
    """Statut détaillé du service"""
    return jsonify({
        "service": "LLM Service v2.0 Hybrid",
        "model_loaded": model_loaded,
        "transformers_available": TRANSFORMERS_AVAILABLE,
        "config_available": os.path.exists('/config/prompts.json'),
        "endpoints_v1": ["/classify", "/summarize"],
        "endpoints_v2": ["/classify_v2", "/summarize_v2", "/generate_metadata"],
        "utilities": ["/health", "/status"],
        "version": "2.0_hybrid"
    })

if __name__ == '__main__':
    # Chargement du modèle au démarrage
    logger.info("🚀 Démarrage du service LLM v2.0 Hybrid...")
    load_model()
    
    # Démarrage du serveur
    app.run(host='0.0.0.0', port=5000, debug=False)