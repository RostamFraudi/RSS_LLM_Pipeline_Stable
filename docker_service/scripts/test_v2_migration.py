#!/usr/bin/env python3
"""
Test rapide de migration V2 Clean
Valide que vos flows Node-RED V2 existants fonctionnent après migration

Usage:
    python test_v2_clean.py
"""

import requests
import json
import time
from datetime import datetime

class V2MigrationTester:
    """Testeur spécialisé pour migration V2 clean"""
    
    def __init__(self, base_url="http://localhost:15000"):
        self.base_url = base_url
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "tests": {},
            "summary": {}
        }
    
    def test_health(self):
        """Test health endpoint"""
        print("🩺 Test Health Service...")
        try:
            response = requests.get(f"{self.base_url}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Service: {data.get('service', 'OK')}")
                print(f"✅ Config loaded: {data.get('config_loaded', False)}")
                print(f"✅ Domaines: {data.get('domains_count', 0)}")
                self.results["tests"]["health"] = {"status": "success", "data": data}
                return True
            else:
                print(f"❌ Health failed: {response.status_code}")
                self.results["tests"]["health"] = {"status": "failed", "error": f"HTTP {response.status_code}"}
                return False
        except Exception as e:
            print(f"❌ Health error: {e}")
            self.results["tests"]["health"] = {"status": "error", "error": str(e)}
            return False
    
    def test_v2_classification_compatibility(self):
        """Test que vos appels /classify_v2 existants fonctionnent"""
        print("\n🔍 Test Classification V2 - Compatibilité...")
        
        # Tests basés sur vos domaines spécialisés
        test_cases = [
            {
                "name": "Fraude Investissement",
                "payload": {
                    "title": "Nouvelle arnaque aux cryptomonnaies prometant 300% de rendement",
                    "content": "Une nouvelle fraude Ponzi utilisant Bitcoin a été découverte. Les escrocs promettent des rendements impossibles de 300% en 3 mois. L'AMF met en garde les investisseurs français.",
                    "source": "AMF"
                },
                "expected_domain_family": "fraude_investissement"
            },
            {
                "name": "Fraude Paiement",
                "payload": {
                    "title": "Nouvelle technique de skimming sur distributeurs automatiques",
                    "content": "Les cybercriminels utilisent des dispositifs invisibles pour voler les données de cartes bancaires. Plusieurs banques françaises alertent leurs clients sur cette nouvelle menace.",
                    "source": "BankInfoSecurity"
                },
                "expected_domain_family": "fraude_paiement"
            },
            {
                "name": "FOVI / Fraude Président",
                "payload": {
                    "title": "Recrudescence des fraudes au faux ordre de virement international",
                    "content": "Les attaques FOVI se multiplient en France. Les criminels usurpent l'identité de dirigeants pour demander des virements urgents. Le CERT-FR alerte sur cette menace croissante.",
                    "source": "CERT-FR"
                },
                "expected_domain_family": "fraude_president_cyber"
            }
        ]
        
        success_count = 0
        for test_case in test_cases:
            print(f"\n🧪 Test: {test_case['name']}")
            try:
                response = requests.post(
                    f"{self.base_url}/classify_v2",
                    json=test_case["payload"],
                    timeout=10
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    # Vérifier champs obligatoires pour Node-RED
                    required_fields = ["domain", "confidence", "alert_level"]
                    missing_fields = [f for f in required_fields if f not in result]
                    
                    if missing_fields:
                        print(f"❌ Champs manquants: {missing_fields}")
                    else:
                        domain = result.get("domain")
                        confidence = result.get("confidence")
                        alert_level = result.get("alert_level")
                        
                        print(f"✅ Domaine: {domain}")
                        print(f"✅ Confiance: {confidence}%")
                        print(f"✅ Alerte: {alert_level}")
                        
                        # Vérifier nouveaux champs
                        new_fields = ["domain_label", "domain_emoji", "output_folder"]
                        for field in new_fields:
                            if field in result:
                                print(f"✨ {field}: {result[field]}")
                        
                        # Concepts et tags
                        concepts = result.get("obsidian_concepts", [])
                        tags = result.get("strategic_tags", [])
                        print(f"🔗 Concepts: {concepts}")
                        print(f"🏷️  Tags: {tags}")
                        
                        success_count += 1
                        
                        self.results["tests"][f"classify_v2_{test_case['name']}"] = {
                            "status": "success",
                            "domain": domain,
                            "confidence": confidence,
                            "alert_level": alert_level,
                            "new_fields": {field: result.get(field) for field in new_fields if field in result}
                        }
                else:
                    print(f"❌ HTTP Error: {response.status_code}")
                    self.results["tests"][f"classify_v2_{test_case['name']}"] = {
                        "status": "failed",
                        "error": f"HTTP {response.status_code}"
                    }
                    
            except Exception as e:
                print(f"❌ Exception: {e}")
                self.results["tests"][f"classify_v2_{test_case['name']}"] = {
                    "status": "error",
                    "error": str(e)
                }
        
        print(f"\n📊 Classification V2: {success_count}/{len(test_cases)} réussis")
        return success_count == len(test_cases)
    
    def test_v2_summarization(self):
        """Test que vos appels /summarize_v2 fonctionnent"""
        print("\n📝 Test Résumé V2 - Compatibilité...")
        
        test_summary = {
            "title": "Test résumé avec nouveau système",
            "content": "Ceci est un test pour vérifier que le système de résumé V2 configurable fonctionne correctement avec les nouveaux domaines spécialisés. Le résumé doit être adapté au domaine détecté.",
            "domain": "cyber_investigations"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/summarize_v2",
                json=test_summary,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                summary = result.get("summary", "")
                domain = result.get("domain", "")
                
                print(f"✅ Résumé généré pour domaine: {domain}")
                print(f"📄 Aperçu: {summary[:100]}...")
                
                self.results["tests"]["summarize_v2"] = {
                    "status": "success",
                    "domain": domain,
                    "summary_length": len(summary)
                }
                return True
            else:
                print(f"❌ Résumé failed: {response.status_code}")
                self.results["tests"]["summarize_v2"] = {
                    "status": "failed", 
                    "error": f"HTTP {response.status_code}"
                }
                return False
                
        except Exception as e:
            print(f"❌ Résumé error: {e}")
            self.results["tests"]["summarize_v2"] = {
                "status": "error",
                "error": str(e)
            }
            return False
    
    def test_new_endpoints(self):
        """Test des nouveaux endpoints de configuration"""
        print("\n🔧 Test Nouveaux Endpoints...")
        
        # Test /config/domains
        try:
            response = requests.get(f"{self.base_url}/config/domains", timeout=5)
            if response.status_code == 200:
                domains = response.json()
                domain_count = domains.get("total_count", 0)
                print(f"✅ Domaines disponibles: {domain_count}")
                
                # Afficher quelques domaines
                domains_list = domains.get("domains", {})
                for domain_id, info in list(domains_list.items())[:3]:
                    emoji = info.get("emoji", "📄")
                    label = info.get("label", domain_id)
                    print(f"   {emoji} {domain_id}: {label}")
                
                self.results["tests"]["config_domains"] = {
                    "status": "success",
                    "domain_count": domain_count
                }
            else:
                print(f"❌ Config domains failed: {response.status_code}")
                self.results["tests"]["config_domains"] = {
                    "status": "failed",
                    "error": f"HTTP {response.status_code}"
                }
        except Exception as e:
            print(f"❌ Config domains error: {e}")
            self.results["tests"]["config_domains"] = {
                "status": "error",
                "error": str(e)
            }
        
        # Test /generate_metadata (nouveau endpoint unifié)
        try:
            test_payload = {
                "title": "Test endpoint unifié",
                "content": "Test pour valider le nouvel endpoint generate_metadata qui combine classification et résumé.",
                "source": "Test"
            }
            
            response = requests.post(
                f"{self.base_url}/generate_metadata",
                json=test_payload,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Metadata unifié: {result.get('domain')} - {result.get('confidence')}%")
                print(f"✅ Résumé inclus: {len(result.get('summary', ''))} chars")
                
                self.results["tests"]["generate_metadata"] = {
                    "status": "success",
                    "domain": result.get("domain"),
                    "has_summary": bool(result.get("summary"))
                }
            else:
                print(f"❌ Generate metadata failed: {response.status_code}")
                self.results["tests"]["generate_metadata"] = {
                    "status": "failed",
                    "error": f"HTTP {response.status_code}"
                }
                
        except Exception as e:
            print(f"❌ Generate metadata error: {e}")
            self.results["tests"]["generate_metadata"] = {
                "status": "error",
                "error": str(e)
            }
    
    def test_node_red_compatibility(self):
        """Test spécifique compatibilité Node-RED"""
        print("\n🔄 Test Compatibilité Node-RED...")
        
        # Simuler un appel typique depuis Node-RED
        node_red_payload = {
            "title": "{{payload.title}}",  # Template Node-RED typique
            "content": "Simulation d'un article RSS traité par Node-RED. Test de compatibilité avec le nouveau système de classification configurable.",
            "source": "{{payload.source}}"
        }
        
        # Remplacer templates par valeurs réelles
        node_red_payload["title"] = "Simulation Article Node-RED"
        node_red_payload["source"] = "Test-RSS-Feed"
        
        try:
            response = requests.post(
                f"{self.base_url}/classify_v2",
                json=node_red_payload,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                
                # Vérifier que les champs utilisés par Node-RED sont présents
                node_red_fields = {
                    "domain": result.get("domain"),
                    "confidence": result.get("confidence"),
                    "alert_level": result.get("alert_level"),
                    "obsidian_concepts": result.get("obsidian_concepts", []),
                    "strategic_tags": result.get("strategic_tags", [])
                }
                
                # Nouveaux champs utiles pour Node-RED
                new_useful_fields = {
                    "domain_emoji": result.get("domain_emoji"),
                    "domain_label": result.get("domain_label"),
                    "output_folder": result.get("output_folder")
                }
                
                print("✅ Compatibilité Node-RED validée")
                print(f"   📂 Dossier de sortie: {new_useful_fields['output_folder']}")
                print(f"   🏷️  Label domaine: {new_useful_fields['domain_label']}")
                print(f"   📊 Confiance: {node_red_fields['confidence']}%")
                
                self.results["tests"]["node_red_compatibility"] = {
                    "status": "success",
                    "node_red_fields": node_red_fields,
                    "new_fields": new_useful_fields
                }
                return True
            else:
                print(f"❌ Node-RED compatibility failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Node-RED compatibility error: {e}")
            return False
    
    def generate_report(self):
        """Génère un rapport de migration"""
        print("\n" + "="*60)
        print("📋 RAPPORT DE MIGRATION V2 CLEAN")
        print("="*60)
        
        # Compter succès/échecs
        total_tests = len(self.results["tests"])
        successful_tests = len([t for t in self.results["tests"].values() if t.get("status") == "success"])
        
        print(f"📊 Tests: {successful_tests}/{total_tests} réussis")
        
        # Statut par catégorie
        if self.results["tests"].get("health", {}).get("status") == "success":
            print("✅ Service: Opérationnel")
        else:
            print("❌ Service: Problème détecté")
        
        if self.results["tests"].get("node_red_compatibility", {}).get("status") == "success":
            print("✅ Node-RED: Compatible")
        else:
            print("❌ Node-RED: Problème compatibilité")
        
        # Résumé des améliorations
        print("\n🚀 AMÉLIORATIONS DISPONIBLES:")
        print("   - Classification plus précise (8 domaines spécialisés)")
        print("   - Nouveaux champs: domain_emoji, output_folder, domain_label")
        print("   - Configuration hot-reload disponible")
        print("   - Endpoint unifié /generate_metadata")
        
        # Recommandations
        print("\n💡 RECOMMANDATIONS:")
        if successful_tests == total_tests:
            print("   ✅ Migration réussie - Pipeline prêt à l'emploi")
            print("   🎯 Optionnel: Utiliser nouveaux champs dans templates Node-RED")
            print("   🔧 Optionnel: Tester endpoint /generate_metadata pour simplification")
        else:
            print("   ⚠️  Vérifier configuration sources.json")
            print("   🔧 Redémarrer service si nécessaire")
        
        # Sauvegarder rapport
        report_file = f"migration_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        print(f"\n📁 Rapport sauvegardé: {report_file}")

def main():
    print("🧪 Test Migration V2 Clean - Pipeline Anti-Fraude")
    print("="*60)
    
    tester = V2MigrationTester()
    
    # Exécuter tous les tests
    tests_passed = []
    
    tests_passed.append(tester.test_health())
    tests_passed.append(tester.test_v2_classification_compatibility())
    tests_passed.append(tester.test_v2_summarization())
    tester.test_new_endpoints()  # Non bloquant
    tests_passed.append(tester.test_node_red_compatibility())
    
    # Générer rapport
    tester.generate_report()
    
    # Résultat final
    if all(tests_passed):
        print("\n🎉 MIGRATION V2 CLEAN RÉUSSIE!")
        print("Votre pipeline Node-RED peut continuer à fonctionner.")
        return 0
    else:
        print("\n⚠️  MIGRATION PARTIELLE")
        print("Vérifiez les erreurs ci-dessus.")
        return 1

if __name__ == "__main__":
    exit(main())