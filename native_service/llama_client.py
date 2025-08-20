"""
Client léger pour serveurs llama.cpp
Optimisé pour RSS + LLM Pipeline Native
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
                
                # Parse la classification
                domain = self._parse_classification(raw_classification, domains)
                confidence = self._calculate_confidence(raw_classification, domain)
                
                processing_time = time.time() - start_time
                
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
        
        prompt = f"""Summarize this {domain.replace('_', ' ')} article in French (2-3 sentences):

Title: {title}
Content: {content[:800]}

Summary:"""
        
        try:
            response = requests.post(
                f"{self.summary_url}/completion",
                json={
                    "prompt": prompt,
                    "max_tokens": self.summary_config.get('max_tokens', 200),
                    "temperature": self.summary_config.get('temperature', 0.3)
                },
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                summary = result.get("content", "").strip()
                
                # Nettoyage du résumé
                summary = self._clean_summary(summary)
                
                processing_time = time.time() - start_time
                
                return {
                    "summary": summary,
                    "method": "llama_cpp_qwen2",
                    "processing_time": processing_time
                }
            else:
                logger.error(f"Summary API error: {response.status_code}")
                return self._fallback_summary(title, content, domain)
                
        except Exception as e:
            logger.error(f"Summary failed: {e}")
            return self._fallback_summary(title, content, domain)
    
    def health_check(self) -> Dict:
        """Vérification santé des serveurs"""
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
        """Parse et valide la classification"""
        raw_output = raw_output.lower().strip()
        
        # Chercher correspondance exacte
        for domain in valid_domains:
            if domain.lower() in raw_output:
                return domain
                
        # Fallback : premier domaine valide mentionné
        for domain in valid_domains:
            domain_parts = domain.split('_')
            if any(part in raw_output for part in domain_parts):
                return domain
                
        # Fallback final
        return "cyber_investigations"
    
    def _calculate_confidence(self, raw_output: str, domain: str) -> int:
        """Calcule la confiance de la classification"""
        if domain.lower() in raw_output.lower():
            return 85
        elif any(part in raw_output.lower() for part in domain.split('_')):
            return 70
        else:
            return 50
    
    def _clean_summary(self, summary: str) -> str:
        """Nettoie le résumé généré"""
        # Supprimer préfixes courants
        prefixes = ["summary:", "résumé:", "en résumé:", "tldr:"]
        summary_lower = summary.lower()
        
        for prefix in prefixes:
            if summary_lower.startswith(prefix):
                summary = summary[len(prefix):].strip()
                break
                
        return summary
    
    def _fallback_classification(self, title: str, content: str, domains: List[str]) -> Dict:
        """Classification fallback par mots-clés"""
        text = (title + " " + content).lower()
        
        # Mots-clés par domaine
        keywords = {
            "fraude_investissement": ["investissement", "placement", "arnaque", "ponzi", "escroquerie"],
            "fraude_paiement": ["paiement", "carte", "bancaire", "virement", "phishing"],
            "fraude_president_cyber": ["fovi", "président", "dirigeant", "virement", "urgence"],
            "fraude_crypto": ["crypto", "bitcoin", "blockchain", "token", "rugpull"],
            "cyber_investigations": ["hack", "breach", "cyberattaque", "malware", "vulnérabilité"]
        }
        
        scores = {}
        for domain in domains:
            domain_keywords = keywords.get(domain, [])
            score = sum(1 for kw in domain_keywords if kw in text)
            scores[domain] = score
            
        best_domain = max(scores, key=scores.get) if scores else "cyber_investigations"
        confidence = min(80, max(40, scores.get(best_domain, 0) * 20))
        
        return {
            "domain": best_domain,
            "confidence": confidence,
            "method": "fallback_keywords",
            "processing_time": 0.05
        }
    
    def _fallback_summary(self, title: str, content: str, domain: str) -> Dict:
        """Résumé fallback par template"""
        summary = f"Article sur {domain.replace('_', ' ')} : {title}. {content[:150]}..."
        
        return {
            "summary": summary,
            "method": "fallback_template", 
            "processing_time": 0.01
        }
