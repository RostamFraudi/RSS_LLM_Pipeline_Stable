#!/usr/bin/env python3
"""
Tests d'intégration pour RSS LLM Pipeline Native
"""

import requests
import json
import time
import sys
from pathlib import Path

# Ajouter le chemin du service
sys.path.append(str(Path(__file__).parent.parent / "native_service"))

def test_llama_servers():
    """Test des serveurs llama.cpp"""
    print("🧪 Test serveurs llama.cpp...")
    
    # Test classification
    try:
        response = requests.post(
            "http://localhost:8080/completion",
            json={
                "prompt": "Classify: security breach. Category:",
                "max_tokens": 10,
                "temperature": 0.1
            },
            timeout=10
        )
        if response.status_code == 200:
            print("✅ TinyLlama (classification) OK")
        else:
            print(f"❌ TinyLlama erreur: {response.status_code}")
    except Exception as e:
        print(f"❌ TinyLlama non accessible: {e}")
    
    # Test résumé
    try:
        response = requests.post(
            "http://localhost:8081/completion",
            json={
                "prompt": "Summarize: Test article about cybersecurity. Summary:",
                "max_tokens": 50,
                "temperature": 0.3
            },
            timeout=10
        )
        if response.status_code == 200:
            print("✅ Qwen2 (résumés) OK")
        else:
            print(f"❌ Qwen2 erreur: {response.status_code}")
    except Exception as e:
        print(f"❌ Qwen2 non accessible: {e}")

def test_api_service():
    """Test du service API Python"""
    print("🧪 Test service API...")
    
    # Health check
    try:
        response = requests.get("http://localhost:15000/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Service API OK - Version: {data.get('version', 'N/A')}")
        else:
            print(f"❌ API erreur: {response.status_code}")
    except Exception as e:
        print(f"❌ API non accessible: {e}")
        return
    
    # Test classification complète
    test_data = {
        "title": "Major Data Breach at Financial Institution",
        "content": "Hackers accessed customer payment information through sophisticated cyberattack",
        "source": "Security News"
    }
    
    try:
        response = requests.post(
            "http://localhost:15000/generate_metadata",
            json=test_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Classification: {result.get('domain')} ({result.get('confidence')}%)")
            print(f"   Méthode: {result.get('classification_method')}")
            print(f"   Temps: {result.get('processing_time', 0):.2f}s")
        else:
            print(f"❌ Classification erreur: {response.status_code}")
    except Exception as e:
        print(f"❌ Classification failed: {e}")
    
    # Test résumé
    try:
        response = requests.post(
            "http://localhost:15000/summarize",
            json={
                "title": test_data["title"],
                "content": test_data["content"],
                "domain": "cyber_investigations"
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Résumé généré ({result.get('method')})")
            print(f"   Temps: {result.get('processing_time', 0):.2f}s")
        else:
            print(f"❌ Résumé erreur: {response.status_code}")
    except Exception as e:
        print(f"❌ Résumé failed: {e}")

def test_performance():
    """Test de performance"""
    print("🧪 Test de performance...")
    
    test_data = {
        "title": "Test Performance",
        "content": "Quick test for performance measurement",
        "source": "Test"
    }
    
    times = []
    for i in range(5):
        start = time.time()
        try:
            response = requests.post(
                "http://localhost:15000/generate_metadata",
                json=test_data,
                timeout=10
            )
            if response.status_code == 200:
                duration = time.time() - start
                times.append(duration)
                print(f"   Test {i+1}: {duration:.2f}s")
        except:
            print(f"   Test {i+1}: FAILED")
    
    if times:
        avg_time = sum(times) / len(times)
        print(f"✅ Performance moyenne: {avg_time:.2f}s")
        if avg_time < 1.0:
            print("🚀 Performance excellente !")
        elif avg_time < 2.0:
            print("👍 Performance bonne")
        else:
            print("⚠️ Performance à optimiser")

if __name__ == "__main__":
    print("🧪 Tests RSS LLM Pipeline Native")
    print("================================")
    
    test_llama_servers()
    print()
    test_api_service()
    print()
    test_performance()
    
    print("\n🏁 Tests terminés")
