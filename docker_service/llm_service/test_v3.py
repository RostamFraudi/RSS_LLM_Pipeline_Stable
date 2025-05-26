#!/usr/bin/env python3
"""
Script de test pour RSS LLM Service v3
Teste tous les endpoints avec des exemples réels
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:15000"  # Port de la v3
# BASE_URL = "http://localhost:5000"  # Si lancé directement

# Couleurs pour l'affichage
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_test(name):
    print(f"\n{Colors.BLUE}═══ Test: {name} ═══{Colors.END}")

def print_success(msg):
    print(f"{Colors.GREEN}✓ {msg}{Colors.END}")

def print_error(msg):
    print(f"{Colors.RED}✗ {msg}{Colors.END}")

def print_info(msg):
    print(f"{Colors.YELLOW}ℹ {msg}{Colors.END}")

# Tests
def test_health():
    print_test("Health Check")
    try:
        response = requests.get(f"{BASE_URL}/health")
        data = response.json()
        print_success(f"Service status: {data['status']}")
        print_info(f"LLM loaded: {data['llm_loaded']}")
        print_info(f"Version: {data['version']}")
        return data['llm_loaded']
    except Exception as e:
        print_error(f"Health check failed: {e}")
        return False

def test_status():
    print_test("Status Détaillé")
    try:
        response = requests.get(f"{BASE_URL}/status")
        data = response.json()
        print_success("Status retrieved")
        print_info(f"Architecture: {data['architecture']}")
        print_info(f"Models: {json.dumps(data['models'], indent=2)}")
    except Exception as e:
        print_error(f"Status failed: {e}")

def test_classification():
    print_test("Classification LLM")
    
    test_cases = [
        {
            "title": "Major Data Breach Exposes 50 Million Credit Card Records",
            "content": "A sophisticated cyberattack on payment processor has resulted in massive data breach. Hackers exploited vulnerability to steal credit card information.",
            "source": "KrebsOnSecurity",
            "expected": "fraude_paiement"
        },
        {
            "title": "CEO of Tech Startup Falls Victim to Wire Transfer Scam",
            "content": "Executive received urgent email appearing to be from board member requesting immediate wire transfer for acquisition. Company lost $2.3 million.",
            "source": "BankInfoSecurity",
            "expected": "fraude_president_cyber"
        },
        {
            "title": "New Cryptocurrency Ponzi Scheme Targets Investors",
            "content": "Fraudulent investment platform promises 200% returns on Bitcoin investments. Regulatory authorities issue warning about pyramid scheme.",
            "source": "CoinDesk",
            "expected": "fraude_crypto"
        }
    ]
    
    for i, test in enumerate(test_cases, 1):
        print(f"\n{Colors.YELLOW}Test {i}/{len(test_cases)}: {test['title'][:50]}...{Colors.END}")
        
        try:
            start_time = time.time()
            response = requests.post(f"{BASE_URL}/generate_metadata", json=test)
            duration = time.time() - start_time
            
            data = response.json()
            
            print_success(f"Classification: {data['domain']} (expected: {test['expected']})")
            print_info(f"Confidence: {data['confidence']}%")
            print_info(f"Method: {data['classification_method']}")
            print_info(f"Alert level: {data['alert_level']}")
            print_info(f"Tags: {', '.join(data['tags'])}")
            print_info(f"Processing time: {duration:.2f}s")
            
            if data['domain'] == test['expected']:
                print_success("Classification correcte! ✓")
            else:
                print_error("Classification incorrecte")
                
        except Exception as e:
            print_error(f"Test failed: {e}")

def test_summary():
    print_test("Génération de Résumé")
    
    test_article = {
        "title": "Ransomware Attack Disrupts Hospital Operations",
        "content": """A major hospital system has been hit by a ransomware attack that has encrypted critical patient data 
        and forced the facility to divert emergency patients to other hospitals. The attack, which began early Monday morning, 
        has affected multiple locations across the healthcare network. Security experts believe the attackers gained initial 
        access through a phishing email sent to hospital staff. The ransomware variant has been identified as a new strain 
        of LockBit, known for targeting healthcare institutions. Hospital administrators are working with federal law 
        enforcement and cybersecurity firms to respond to the incident. No ransom amount has been disclosed, but sources 
        suggest it could be in the millions of dollars. Patient care continues with backup systems, though some elective 
        procedures have been postponed.""",
        "domain": "cyber_investigations"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/summarize", json=test_article)
        data = response.json()
        
        print_success("Summary generated")
        print_info(f"Method: {data['method']}")
        print_info(f"Processing time: {data['processing_time']:.2f}s")
        print(f"\n{Colors.BLUE}Summary:{Colors.END}")
        print(data['summary'])
        
    except Exception as e:
        print_error(f"Summary test failed: {e}")

def test_tags_deduplication():
    print_test("Déduplication des Tags")
    
    # Article avec mots répétés qui pourraient générer des doublons
    test_article = {
        "title": "Cyber Attack: Ransomware Cyber Threat Targets Cyber Infrastructure",
        "content": "Cybercrime cybersecurity cyber attack ransomware malware threat cyber",
        "source": "Test"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/generate_metadata", json=test_article)
        data = response.json()
        
        tags = data['tags']
        unique_tags = list(set(tags))
        
        print_info(f"Tags générés: {tags}")
        print_info(f"Nombre de tags: {len(tags)}")
        print_info(f"Tags uniques: {len(unique_tags)}")
        
        if len(tags) == len(unique_tags):
            print_success("Pas de doublons! ✓")
        else:
            print_error("Doublons détectés")
            
    except Exception as e:
        print_error(f"Test failed: {e}")

def test_language_consistency():
    print_test("Cohérence Linguistique des Tags")
    
    # Article en français pour tester que les tags restent en anglais
    test_article = {
        "title": "Attaque par ransomware dans un hôpital français",
        "content": "Une cyberattaque majeure a touché l'hôpital. Les pirates ont utilisé un ransomware pour chiffrer les données.",
        "source": "CERT-FR"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/generate_metadata", json=test_article)
        data = response.json()
        
        tags = data['tags']
        print_info(f"Tags: {tags}")
        
        # Vérifier que les tags sont en anglais
        french_words = ['attaque', 'pirate', 'hôpital', 'cyber', 'sécurité']
        has_french = any(any(fr in tag for fr in french_words) for tag in tags)
        
        if not has_french:
            print_success("Tous les tags sont en anglais! ✓")
        else:
            print_error("Certains tags contiennent du français")
            
    except Exception as e:
        print_error(f"Test failed: {e}")

def main():
    print(f"\n{Colors.BLUE}{'='*50}{Colors.END}")
    print(f"{Colors.BLUE}RSS LLM Service v3 - Test Suite{Colors.END}")
    print(f"{Colors.BLUE}{'='*50}{Colors.END}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Target: {BASE_URL}")
    
    # Vérifier que le service est accessible
    llm_loaded = test_health()
    
    if not llm_loaded:
        print_info("\n⚠️  LLM non chargé - Tests en mode fallback")
    
    # Lancer tous les tests
    test_status()
    test_classification()
    test_summary()
    test_tags_deduplication()
    test_language_consistency()
    
    print(f"\n{Colors.BLUE}{'='*50}{Colors.END}")
    print(f"{Colors.GREEN}Tests terminés!{Colors.END}")
    print(f"{Colors.BLUE}{'='*50}{Colors.END}")

if __name__ == "__main__":
    main()
