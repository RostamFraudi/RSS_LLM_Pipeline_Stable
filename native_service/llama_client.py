"""
Client léger pour serveurs llama.cpp
Optimisé pour RSS + LLM Pipeline Native - VERSION ASYNC AMÉLIORÉE
"""

import httpx
import json
import logging
import time
from typing import Dict, Optional, List
import asyncio

logger = logging.getLogger(__name__)

class LlamaClient:
    """Client pour serveurs llama.cpp multiples (Version Asynchrone)"""
    
    def __init__(self, config: Dict, prompts: Dict = None):
        self.classification_config = config.get('classification_server', {})
        self.summary_config = config.get('summary_server', {})
        self.timeout = httpx.Timeout(60.0, connect=10.0)
        
        # URLs des serveurs
        self.classification_url = self.classification_config.get('url', 'http://localhost:8080')
        self.summary_url = self.summary_config.get('url', 'http://localhost:8081')
        
        # Prompts
        self.prompts = prompts or {}

        # Client HTTP persistant
        self._client = None

        logger.info(f"🦙 LlamaClient initialisé")
        logger.info(f"   Classification: {self.classification_url}")
        logger.info(f"   Summary: {self.summary_url}")

    async def get_client(self):
        """Initialise ou retourne le client HTTP persistant"""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=self.timeout)
        return self._client

    async def close(self):
        """Ferme le client HTTP"""
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def _post_completion(self, url: str, payload: Dict) -> Optional[Dict]:
        """Effectue un appel POST asynchrone au serveur llama.cpp"""
        client = await self.get_client()
        try:
            response = await client.post(f"{url}/completion", json=payload)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Erreur d'appel LLM à {url}: {e}")
            return None

    async def classify_domain(self, title: str, content: str, domains: List[str]) -> Dict:
        """Classification avec TinyLlama (Asynchrone)"""
        start_time = time.time()

        # Construction du prompt
        template = self.prompts.get('classification', {}).get('base_prompt')
        if template:
            try:
                # Gérer domains dynamiquement
                domains_str = ", ".join(domains)
                prompt = template.format(domains=domains_str, title=title, content=content[:500])
            except KeyError:
                prompt = f"Classify this article into ONE category:\n{', '.join(domains)}\n\nTitle: {title}\nContent: {content[:500]}\n\nCategory:"
        else:
            domains_desc = "\n".join([f"- {domain}" for domain in domains])
            prompt = f"Classify this article into ONE category:\n\n{domains_desc}\n\nTitle: {title}\nContent: {content[:500]}\n\nCategory:"

        logger.info(f"🔍 CLASSIFICATION: {title[:50]}...")

        payload = {
            "prompt": prompt,
            "max_tokens": self.classification_config.get('max_tokens', 20),
            "temperature": self.classification_config.get('temperature', 0.1),
            "stop": ["\n", ".", ":", ","]
        }

        result = await self._post_completion(self.classification_url, payload)

        if result:
            raw_classification = result.get("content", "").strip()
            logger.debug(f"📝 RÉPONSE BRUTE: '{raw_classification}'")
            
            domain = self._parse_classification(raw_classification, domains)
            confidence = self._calculate_confidence(raw_classification, domain)
            
            processing_time = time.time() - start_time
            logger.info(f"✅ CLASSIFICATION: {domain} ({confidence}%) en {processing_time:.2f}s")

            return {
                "domain": domain,
                "confidence": confidence,
                "method": "llama_cpp_tinyllama",
                "processing_time": processing_time,
                "raw_output": raw_classification
            }

        return await self._fallback_classification(title, content, domains)

    async def generate_summary(self, title: str, content: str, domain: str) -> Dict:
        """Résumé avec Qwen2 (Asynchrone)"""
        start_time = time.time()
        
        if not domain or domain == "autre":
            domain = "cyber_investigations"
        
        # Mapping français pour domaines
        domain_french_map = {
            'fraude_investissement': 'fraude aux investissements',
            'fraude_paiement': 'fraude aux moyens de paiement', 
            'fraude_president_cyber': 'fraude au président (FOVI)',
            'fraude_ecommerce': 'fraude e-commerce',
            'supply_chain_cyber': 'attaques supply chain',
            'intelligence_economique': 'intelligence économique',
            'fraude_crypto': 'fraude cryptomonnaies',
            'cyber_investigations': 'investigations cybercriminalité'
        }
        domain_french = domain_french_map.get(domain, 'cybersécurité')
        
        template = self.prompts.get('summary', {}).get('base_prompt')
        if template:
            try:
                prompt = template.format(domain=domain_french, title=title, content=content[:800])
            except KeyError:
                prompt = f"Summarize this {domain_french} article in French:\n\nTitle: {title}\nContent: {content[:800]}\n\nSummary:"
        else:
            prompt = f"Vous êtes un analyste cybersécurité francophone expert.\n\nMISSION : Analysez cet article sur {domain_french} et créez un résumé structuré.\n\nARTICLE :\nTitre : {title}\nContenu : {content[:800]}\n\nFORMAT OBLIGATOIRE :\n🎯 **Fait principal** : [1 phrase]\n🔍 **Impact** : [1 phrase]\n⚠️ **Recommandation** : [1 phrase]\n\nVOTRE RÉSUMÉ STRUCTURÉ :"

        logger.info(f"📝 RÉSUMÉ: {domain} - {title[:50]}...")

        payload = {
            "prompt": prompt,
            "max_tokens": self.summary_config.get('max_tokens', 200),
            "temperature": self.summary_config.get('temperature', 0.3),
            "stop": ["ARTICLE", "MISSION", "FORMAT", "\n\n\n"]
        }

        result = await self._post_completion(self.summary_url, payload)

        if result:
            summary = result.get("content", "").strip()
            summary = self._clean_summary(summary)
            
            processing_time = time.time() - start_time
            logger.info(f"✅ RÉSUMÉ OK: {processing_time:.2f}s")
            
            return {
                "summary": summary,
                "method": "llama_cpp_qwen2_structured",
                "processing_time": processing_time
            }

        return await self._fallback_summary(title, content, domain)

    async def health_check(self) -> Dict:
        """Vérification santé détaillée des serveurs"""
        status = {
            "classification": {"status": "down", "url": self.classification_url},
            "summary": {"status": "down", "url": self.summary_url},
            "timestamp": time.time()
        }
        
        client = await self.get_client()
        # Test classification server
        try:
            response = await client.get(f"{self.classification_url}/health", timeout=5.0)
            if response.status_code == 200:
                status["classification"]["status"] = "ok"
                status["classification"]["details"] = response.json()
        except Exception as e:
            status["classification"]["error"] = str(e)

        # Test summary server
        try:
            response = await client.get(f"{self.summary_url}/health", timeout=5.0)
            if response.status_code == 200:
                status["summary"]["status"] = "ok"
                status["summary"]["details"] = response.json()
        except Exception as e:
            status["summary"]["error"] = str(e)
            
        return status
    
    def _parse_classification(self, raw_output: str, valid_domains: List[str]) -> str:
        """Parse et valide la classification avec plus de robustesse"""
        raw_output = raw_output.lower().strip()
        
        # Match exact
        for domain in valid_domains:
            if domain.lower() == raw_output:
                return domain
        
        # Match contenu
        for domain in valid_domains:
            if domain.lower() in raw_output:
                return domain
                
        # Match par parties (mots significatifs)
        for domain in valid_domains:
            parts = [p for p in domain.split('_') if len(p) > 3]
            if any(part in raw_output for part in parts):
                return domain
        
        # Mots-clés universels
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
                return domain
        
        return "cyber_investigations"
    
    def _calculate_confidence(self, raw_output: str, domain: str) -> int:
        """Calcule un score de confiance basé sur la qualité du match"""
        raw_output = raw_output.lower()
        domain_lower = domain.lower()

        if domain_lower == raw_output:
            return 95
        elif domain_lower in raw_output:
            return 85
        elif any(part in raw_output for part in domain_lower.split('_') if len(part) > 3):
            return 70
        else:
            return 50
    
    def _clean_summary(self, summary: str) -> str:
        """Nettoie et structure le résumé si nécessaire"""
        prefixes = ["votre résumé structuré:", "résumé:", "summary:", "tldr:", "voici"]
        summary_lower = summary.lower()
        
        for prefix in prefixes:
            if summary_lower.startswith(prefix):
                summary = summary[len(prefix):].strip()
                break
        
        # Vérification des emojis de structure
        required_elements = ["🎯", "🔍", "⚠️"]
        if not all(emoji in summary for emoji in required_elements):
            # Transformation en format structuré si manquant
            lines = [l.strip() for l in summary.split('.') if l.strip()]
            if len(lines) >= 1:
                summary = f"🎯 **Fait principal** : {lines[0]}.\n🔍 **Impact** : {lines[1] if len(lines) > 1 else 'Impact à déterminer'}.\n⚠️ **Recommandation** : {lines[2] if len(lines) > 2 else 'Surveillance proactive recommandée'}."
        
        return summary
    
    async def _fallback_classification(self, title: str, content: str, domains: List[str]) -> Dict:
        """Classification de repli par recherche de mots-clés"""
        text = (title + " " + content).lower()
        logger.warning(f"🔄 FALLBACK CLASSIFICATION utilisé pour: {title[:50]}")
        
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
            
        best_domain = max(scores, key=scores.get) if scores and max(scores.values()) > 0 else "cyber_investigations"
        confidence = min(80, max(40, scores.get(best_domain, 0) * 15))
        
        return {
            "domain": best_domain,
            "confidence": confidence,
            "method": "fallback_keywords",
            "processing_time": 0.05
        }
    
    async def _fallback_summary(self, title: str, content: str, domain: str) -> Dict:
        """Résumé de repli par gabarit"""
        logger.warning(f"🔄 FALLBACK SUMMARY utilisé pour: {title[:50]}")
        summary = f"🎯 **Fait principal** : Article sur {domain.replace('_', ' ')} intitulé \"{title}\".\n🔍 **Impact** : Analyse des risques cyber associée à cette publication dans le domaine {domain}.\n⚠️ **Recommandation** : Rester vigilant et suivre l'évolution de cette menace via les canaux officiels."
        
        return {
            "summary": summary,
            "method": "fallback_structured_template", 
            "processing_time": 0.01
        }
