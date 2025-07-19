#!/bin/bash

# vLLM双模型停止脚本
# 停止Qwen3-Embedding-0.6B和Qwen3-Reranker-0.6B模型服务

set -e

echo "Stopping vLLM model services..."

# 检查PID文件是否存在
if [ -f "logs/embedding.pid" ]; then
    EMBEDDING_PID=$(cat logs/embedding.pid)
    if ps -p $EMBEDDING_PID > /dev/null 2>&1; then
        echo "Stopping Qwen3-Embedding-0.6B (PID: $EMBEDDING_PID)..."
        kill -TERM $EMBEDDING_PID
        # 等待进程优雅退出
        sleep 5
        if ps -p $EMBEDDING_PID > /dev/null 2>&1; then
            echo "Force killing Qwen3-Embedding-0.6B..."
            kill -KILL $EMBEDDING_PID
        fi
        echo "✓ Qwen3-Embedding-0.6B stopped"
    else
        echo "Qwen3-Embedding-0.6B process not found"
    fi
    rm -f logs/embedding.pid
else
    echo "No embedding model PID file found"
fi

if [ -f "logs/reranker.pid" ]; then
    RERANKER_PID=$(cat logs/reranker.pid)
    if ps -p $RERANKER_PID > /dev/null 2>&1; then
        echo "Stopping Qwen3-Reranker-0.6B (PID: $RERANKER_PID)..."
        kill -TERM $RERANKER_PID
        # 等待进程优雅退出
        sleep 5
        if ps -p $RERANKER_PID > /dev/null 2>&1; then
            echo "Force killing Qwen3-Reranker-0.6B..."
            kill -KILL $RERANKER_PID
        fi
        echo "✓ Qwen3-Reranker-0.6B stopped"
    else
        echo "Qwen3-Reranker-0.6B process not found"
    fi
    rm -f logs/reranker.pid
else
    echo "No reranker model PID file found"
fi

# 额外检查并清理可能残留的vllm进程
echo "Checking for any remaining vllm processes..."
VLLM_PIDS=$(pgrep -f "vllm serve" || true)
if [ ! -z "$VLLM_PIDS" ]; then
    echo "Found remaining vllm processes: $VLLM_PIDS"
    echo "Cleaning up remaining processes..."
    pkill -f "vllm serve" || true
    sleep 2
fi

echo "All vLLM model services stopped."