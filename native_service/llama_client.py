"""
Client léger pour serveurs llama.cpp
Optimisé pour RSS + LLM Pipeline Native - VERSION COMPLÈTE
"""

import requests
import json
import logging
import time
from typing import Dict, Optional, List

logger = logging.getLogger(__name__)

class LlamaClient:
    """Client pour serveurs llama.cpp multiples"""
    
    def __init__(self, config: Dict):
        self.classification_config = config.get('classification_server', {})
        self.summary_config = config.get('summary_server', {})
        self.timeout = 30
        
        # URLs des serveurs
        self.classification_url = self.classification_config.get('url', 'http://localhost:8080')
        self.summary_url = self.summary_config.get('url', 'http://localhost:8081')
        
        logger.info(f"🦙 LlamaClient initialisé")
        logger.info(f"   Classification: {self.classification_url}")
        logger.info(f"   Summary: {self.summary_url}")
    
    def classify_domain(self, title: str, content: str, domains: List[str]) -> Dict:
        """Classification avec TinyLlama"""
        start_time = time.time()
        
        # Construction du prompt avec domaines dynamiques
        domains_desc = "\n".join([f"- {domain}" for domain in domains])
        prompt = f"""Classify this article into ONE category:

{domains_desc}

Title: {title}
Content: {content[:500]}

Category:"""
        
        try:
            logger.warning(f"🔍 CLASSIFICATION: {title[:50]}...")
            
            response = requests.post(
                f"{self.classification_url}/completion",
                json={
                    "prompt": prompt,
                    "max_tokens": self.classification_config.get('max_tokens', 20),
                    "temperature": self.classification_config.get('temperature', 0.1),
                    "stop": ["\n", ".", ":", ","]
                },
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                raw_classification = result.get("content", "").strip()
                
                logger.warning(f"📝 RÉPONSE BRUTE: '{raw_classification}'")
                
                # Parse la classification
                domain = self._parse_classification(raw_classification, domains)
                confidence = self._calculate_confidence(raw_classification, domain)
                
                processing_time = time.time() - start_time
                
                logger.warning(f"✅ CLASSIFICATION: {domain} ({confidence}%)")
                
                return {
                    "domain": domain,
                    "confidence": confidence,
                    "method": "llama_cpp_tinyllama",
                    "processing_time": processing_time,
                    "raw_output": raw_classification
                }
            else:
                logger.error(f"Classification API error: {response.status_code}")
                return self._fallback_classification(title, content, domains)
                
        except Exception as e:
            logger.error(f"Classification failed: {e}")
            return self._fallback_classification(title, content, domains)
    
    def generate_summary(self, title: str, content: str, domain: str) -> Dict:
        """Résumé avec Qwen2"""
        start_time = time.time()
        
        # 🔧 CORRECTION : Gérer domaine "autre" ou vide
        if not domain or domain == "autre":
            domain = "cyber_investigations"
            logger.warning(f"🔧 DOMAINE CORRIGÉ: {domain}")
        
        # Mapping français pour domaines
        domain_french = {
            'fraude_investissement': 'fraude aux investissements',
            'fraude_paiement': 'fraude aux moyens de paiement', 
            'fraude_president_cyber': 'fraude au président (FOVI)',
            'fraude_ecommerce': 'fraude e-commerce',
            'supply_chain_cyber': 'attaques supply chain',
            'intelligence_economique': 'intelligence économique',
            'fraude_crypto': 'fraude cryptomonnaies',
            'cyber_investigations': 'investigations cybercriminalité'
        }.get(domain, 'cybersécurité')
        
        prompt = f"""Vous êtes un analyste cybersécurité francophone expert.

MISSION : Analysez cet article sur {domain_french} et créez un résumé structuré.

ARTICLE :
Titre : {title}
Contenu : {content[:800]}

FORMAT OBLIGATOIRE (respectez exactement) :
🎯 **Fait principal** : [1 phrase sur l'événement clé]
🔍 **Impact** : [1 phrase sur les conséquences/victimes]
⚠️ **Recommandation** : [1 phrase d'action/prévention]

VOTRE RÉSUMÉ STRUCTURÉ :"""

        try:
            logger.warning(f"📝 RÉSUMÉ: {domain} - {title[:50]}...")
            
            response = requests.post(
                f"{self.summary_url}/completion",
                json={
                    "prompt": prompt,
                    "max_tokens": self.summary_config.get('max_tokens', 200),
                    "temperature": self.summary_config.get('temperature', 0.3),
                    "stop": ["ARTICLE", "MISSION", "FORMAT", "\n\n\n"]
                },
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                summary = result.get("content", "").strip()
                
                logger.warning(f"📋 RÉSUMÉ BRUT: '{summary[:100]}...'")
                
                # Nettoyage du résumé
                summary = self._clean_summary(summary)
                
                processing_time = time.time() - start_time
                
                logger.warning(f"✅ RÉSUMÉ OK: {processing_time:.2f}s")
                
                return {
                    "summary": summary,
                    "method": "llama_cpp_qwen2_structured",
                    "processing_time": processing_time
                }
            else:
                logger.error(f"Summary API error: {response.status_code}")
                return self._fallback_summary(title, content, domain)
                
        except Exception as e:
            logger.error(f"Summary failed: {e}")
            return self._fallback_summary(title, content, domain)
    
    def health_check(self) -> Dict:
        """Vérification santé des serveurs - MÉTHODE MANQUANTE"""
        status = {
            "classification": False,
            "summary": False,
            "timestamp": time.time()
        }
        
        # Test classification server
        try:
            response = requests.get(f"{self.classification_url}/health", timeout=5)
            status["classification"] = response.status_code == 200
        except:
            pass
            
        # Test summary server  
        try:
            response = requests.get(f"{self.summary_url}/health", timeout=5)
            status["summary"] = response.status_code == 200
        except:
            pass
            
        return status
    
    def _parse_classification(self, raw_output: str, valid_domains: List[str]) -> str:
        """Parse et valide la classification - MÉTHODE MANQUANTE"""
        raw_output = raw_output.lower().strip()
        
        logger.warning(f"🔍 PARSING: '{raw_output}'")
        
        # Chercher correspondance exacte d'abord
        for domain in valid_domains:
            if domain.lower() == raw_output:
                logger.warning(f"✅ MATCH EXACT: {domain}")
                return domain
        
        # Chercher correspondance partielle
        for domain in valid_domains:
            if domain.lower() in raw_output:
                logger.warning(f"✅ MATCH PARTIEL: {domain}")
                return domain
                
        # Chercher par parties de domaine
        for domain in valid_domains:
            domain_parts = domain.split('_')
            if any(part in raw_output for part in domain_parts):
                logger.warning(f"✅ MATCH PARTIE: {domain}")
                return domain
        
        # Fallback par mots-clés
        keyword_mapping = {
            "investissement": "fraude_investissement",
            "investment": "fraude_investissement", 
            "ponzi": "fraude_investissement",
            "paiement": "fraude_paiement",
            "payment": "fraude_paiement",
            "bancaire": "fraude_paiement",
            "crypto": "fraude_crypto",
            "bitcoin": "fraude_crypto",
            "président": "fraude_president_cyber",
            "ceo": "fraude_president_cyber",
            "fovi": "fraude_president_cyber",
            "ecommerce": "fraude_ecommerce",
            "supply": "supply_chain_cyber",
            "cyber": "cyber_investigations",
            "hack": "cyber_investigations",
            "breach": "cyber_investigations"
        }
        
        for keyword, domain in keyword_mapping.items():
            if keyword in raw_output:
                logger.warning(f"✅ MATCH KEYWORD: {keyword} → {domain}")
                return domain
        
        # Fallback final
        logger.warning(f"❌ FALLBACK: cyber_investigations")
        return "cyber_investigations"
    
    def _calculate_confidence(self, raw_output: str, domain: str) -> int:
        """Calcule la confiance de la classification - MÉTHODE MANQUANTE"""
        if domain.lower() in raw_output.lower():
            return 85
        elif any(part in raw_output.lower() for part in domain.split('_')):
            return 70
        else:
            return 50
    
    def _clean_summary(self, summary: str) -> str:
        """Nettoie le résumé généré - MÉTHODE MANQUANTE"""
        # Supprimer préfixes courants
        prefixes = ["votre résumé structuré:", "résumé:", "summary:", "tldr:", "voici"]
        summary_lower = summary.lower()
        
        for prefix in prefixes:
            if summary_lower.startswith(prefix):
                summary = summary[len(prefix):].strip()
                break
        
        # Assurer que les emojis sont présents
        required_elements = ["🎯", "🔍", "⚠️"]
        if not all(emoji in summary for emoji in required_elements):
            # Fallback : convertir en format structuré
            lines = summary.split('.')[:3]  # Prendre 3 premières phrases
            if len(lines) >= 1:
                summary = f"🎯 **Fait principal** : {lines[0].strip()}.\n🔍 **Impact** : {lines[1].strip() if len(lines) > 1 else 'Impact à déterminer'}.\n⚠️ **Recommandation** : {lines[2].strip() if len(lines) > 2 else 'Surveillance recommandée'}."
        
        return summary
    
    def _fallback_classification(self, title: str, content: str, domains: List[str]) -> Dict:
        """Classification fallback par mots-clés - MÉTHODE MANQUANTE"""
        text = (title + " " + content).lower()
        
        logger.warning(f"🔄 FALLBACK CLASSIFICATION")
        
        # Mots-clés par domaine
        keywords = {
            "fraude_investissement": ["investissement", "placement", "arnaque", "ponzi", "escroquerie"],
            "fraude_paiement": ["paiement", "carte", "bancaire", "virement", "phishing"],
            "fraude_president_cyber": ["fovi", "président", "dirigeant", "virement", "urgence"],
            "fraude_crypto": ["crypto", "bitcoin", "blockchain", "token", "rugpull"],
            "cyber_investigations": ["hack", "breach", "cyberattaque", "malware", "vulnérabilité"],
            "fraude_ecommerce": ["ecommerce", "boutique", "commande", "livraison"],
            "supply_chain_cyber": ["supply", "fournisseur", "chaîne", "logistique"],
            "intelligence_economique": ["économique", "veille", "stratégique", "concurrence"]
        }
        
        scores = {}
        for domain in domains:
            domain_keywords = keywords.get(domain, [])
            score = sum(1 for kw in domain_keywords if kw in text)
            scores[domain] = score
            logger.warning(f"   {domain}: {score} matches")
            
        if scores:
            best_domain = max(scores, key=scores.get)
            confidence = min(80, max(40, scores.get(best_domain, 0) * 15))
        else:
            best_domain = "cyber_investigations"
            confidence = 40
        
        logger.warning(f"✅ FALLBACK RESULT: {best_domain} ({confidence}%)")
        
        return {
            "domain": best_domain,
            "confidence": confidence,
            "method": "fallback_keywords",
            "processing_time": 0.05
        }
    
    def _fallback_summary(self, title: str, content: str, domain: str) -> Dict:
        """Résumé fallback par template - MÉTHODE MANQUANTE"""
        summary = f"""🎯 **Fait principal** : Article sur {domain.replace('_', ' ')} intitulé "{title[:80]}...".
🔍 **Impact** : Situation nécessitant une analyse approfondie des implications sécuritaires.
⚠️ **Recommandation** : Suivi de l'évolution et mise en place de mesures préventives adaptées."""
        
        logger.warning(f"🔄 FALLBACK SUMMARY")
        
        return {
            "summary": summary,
            "method": "fallback_structured_template", 
            "processing_time": 0.01
        }
