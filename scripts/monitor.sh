#!/bin/bash
# Monitoring en temps réel du pipeline

echo "📊 Monitoring RSS LLM Pipeline Native"
echo "======================================"

while true; do
    clear
    echo "📊 Monitoring RSS LLM Pipeline Native - $(date)"
    echo "=============================================="
    echo
    
    # Processus
    echo "🔍 PROCESSUS:"
    ps aux | grep -E "(llama-server|python.*app.py)" | grep -v grep | while read line; do
        echo "   $line"
    done
    echo
    
    # Mémoire
    echo "💾 MÉMOIRE:"
    free -h
    echo
    
    # GPU (si disponible)
    if command -v nvidia-smi &> /dev/null; then
        echo "🎮 GPU:"
        nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits | while read line; do
            echo "   $line"
        done
        echo
    fi
    
    # Connectivité
    echo "🌐 CONNECTIVITÉ:"
    for port in 8080 8081 15000; do
        if curl -s http://localhost:$port/health > /dev/null 2>&1; then
            echo "   ✅ Port $port: OK"
        else
            echo "   ❌ Port $port: KO"
        fi
    done
    echo
    
    # Performance récente
    echo "⚡ PERFORMANCE (5 derniers tests):"
    for i in {1..5}; do
        start=$(date +%s.%N)
        if curl -s -X POST http://localhost:15000/generate_metadata \
           -H "Content-Type: application/json" \
           -d '{"title":"Monitor test","content":"Quick test","source":"Monitor"}' > /dev/null 2>&1; then
            end=$(date +%s.%N)
            duration=$(echo "$end - $start" | bc -l 2>/dev/null || echo "N/A")
            echo "   Test $i: ${duration}s"
        else
            echo "   Test $i: FAILED"
        fi
    done
    
    echo
    echo "🔄 Actualisation dans 30s... (Ctrl+C pour arrêter)"
    sleep 30
done
