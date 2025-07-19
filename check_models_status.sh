#!/bin/bash

# vLLM双模型状态检查脚本
# 检查Qwen3-Embedding-0.6B和Qwen3-Reranker-0.6B模型服务状态

echo "=== vLLM Models Status Check ==="
echo

# 检查进程状态
echo "📋 Process Status:"
if [ -f "logs/embedding.pid" ]; then
    EMBEDDING_PID=$(cat logs/embedding.pid)
    if ps -p $EMBEDDING_PID > /dev/null 2>&1; then
        echo "✓ Qwen3-Embedding-0.6B (PID: $EMBEDDING_PID) - Running"
    else
        echo "✗ Qwen3-Embedding-0.6B (PID: $EMBEDDING_PID) - Not Running"
    fi
else
    echo "✗ Qwen3-Embedding-0.6B - No PID file found"
fi

if [ -f "logs/reranker.pid" ]; then
    RERANKER_PID=$(cat logs/reranker.pid)
    if ps -p $RERANKER_PID > /dev/null 2>&1; then
        echo "✓ Qwen3-Reranker-0.6B (PID: $RERANKER_PID) - Running"
    else
        echo "✗ Qwen3-Reranker-0.6B (PID: $RERANKER_PID) - Not Running"
    fi
else
    echo "✗ Qwen3-Reranker-0.6B - No PID file found"
fi

echo
echo "🌐 API Endpoint Status:"

# 检查Embedding模型API
echo -n "Qwen3-Embedding-0.6B (port 8000): "
if curl -s --connect-timeout 5 http://localhost:8000/health > /dev/null 2>&1; then
    echo "✓ API Responding"
else
    echo "✗ API Not Responding"
fi

# 检查Reranker模型API
echo -n "Qwen3-Reranker-0.6B (port 8001): "
if curl -s --connect-timeout 5 http://localhost:8001/health > /dev/null 2>&1; then
    echo "✓ API Responding"
else
    echo "✗ API Not Responding"
fi

echo
echo "📊 Resource Usage:"

# 显示GPU使用情况
if command -v nvidia-smi &> /dev/null; then
    echo "GPU Memory Usage:"
    nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits | while IFS=',' read -r gpu_id name mem_used mem_total gpu_util; do
        echo "  GPU $gpu_id ($name): ${mem_used}MB/${mem_total}MB (${gpu_util}% util)"
    done
else
    echo "nvidia-smi not available"
fi

echo
echo "📝 Recent Log Activity:"
if [ -f "logs/embedding_model.log" ]; then
    echo "Embedding Model (last 3 lines):"
    tail -n 3 logs/embedding_model.log | sed 's/^/  /'
else
    echo "No embedding model log found"
fi

if [ -f "logs/reranker_model.log" ]; then
    echo "Reranker Model (last 3 lines):"
    tail -n 3 logs/reranker_model.log | sed 's/^/  /'
else
    echo "No reranker model log found"
fi

echo
echo "=== Status Check Complete ==="