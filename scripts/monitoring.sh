#!/bin/bash
# Monitoring RSS LLM Pipeline
echo "📊 Monitoring RSS LLM Pipeline Native"
echo "====================================="

while true; do
    clear
    echo "$(date)"
    echo ""
    
    # Processus
    echo "🔄 Processus actifs:"
    ps aux | grep -E "(llama-server|python.*app.py|node-red)" | grep -v grep || echo "  Aucun processus"
    echo ""
    
    # Ports
    echo "🌐 Ports ouverts:"
    ss -tlnp | grep -E "(8080|8081|15000|18880)" || echo "  Aucun port"
    echo ""
    
    # Ressources
    echo "💾 Ressources:"
    free -h | head -n2
    echo ""
    
    # GPU (si disponible)
    if command -v nvidia-smi &>/dev/null; then
        echo "🎮 GPU:"
        nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader
        echo ""
    fi
    
    sleep 5
done
