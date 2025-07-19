#!/bin/bash

# vLLM双模型启动脚本
# 启动Qwen3-Embedding-0.6B和Qwen3-Reranker-0.6B模型服务

set -e

echo "Starting vLLM model services..."

# 创建日志目录
mkdir -p logs

# 启动Qwen3-Embedding-0.6B模型 (GPU 1, 端口 8000)
echo "Starting Qwen3-Embedding-0.6B on GPU 1, port 8000..."
CUDA_VISIBLE_DEVICES=1 nohup vllm serve /mnt/workspace/model/Qwen/Qwen3-Embedding-0.6B \
    --served-model-name Qwen3-Embedding-0.6B \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.9 \
    --trust-remote-code \
    --max-model-len 32768 \
    --block-size 16 \
    --dtype auto \
    --task embed \
    --hf_overrides '{"is_matryoshka":true}' \
    --port 8000 \
    > logs/embedding_model.log 2>&1 &

EMBEDDING_PID=$!
echo "Qwen3-Embedding-0.6B started with PID: $EMBEDDING_PID"

# 等待一段时间确保第一个模型启动
sleep 10

# 启动Qwen3-Reranker-0.6B模型 (GPU 0, 端口 8001)
echo "Starting Qwen3-Reranker-0.6B on GPU 0, port 8001..."
CUDA_VISIBLE_DEVICES=0 nohup vllm serve /mnt/workspace/model/Qwen/Qwen3-Reranker-0.6B \
    --served-model-name Qwen3-Reranker-0.6B \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.97 \
    --trust-remote-code \
    --max-model-len 32768 \
    --block-size 16 \
    --dtype auto \
    --hf_overrides '{"architectures": ["Qwen3ForSequenceClassification"], "classifier_from_token": ["no", "yes"], "is_original_qwen3_reranker": true}' \
    --task score \
    --port 8001 \
    > logs/reranker_model.log 2>&1 &

RERANKER_PID=$!
echo "Qwen3-Reranker-0.6B started with PID: $RERANKER_PID"

# 保存PID到文件以便后续管理
echo $EMBEDDING_PID > logs/embedding.pid
echo $RERANKER_PID > logs/reranker.pid

echo "Both models are starting up..."
echo "Embedding model log: logs/embedding_model.log"
echo "Reranker model log: logs/reranker_model.log"
echo "PIDs saved to logs/embedding.pid and logs/reranker.pid"

# 等待模型启动完成
echo "Waiting for models to be ready..."
sleep 30

# 检查模型是否正常运行
echo "Checking model status..."

# 检查Embedding模型
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✓ Qwen3-Embedding-0.6B is running on port 8000"
else
    echo "✗ Qwen3-Embedding-0.6B failed to start or not ready yet"
fi

# 检查Reranker模型
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "✓ Qwen3-Reranker-0.6B is running on port 8001"
else
    echo "✗ Qwen3-Reranker-0.6B failed to start or not ready yet"
fi

echo "Model startup script completed."
echo "Use 'tail -f logs/embedding_model.log' to monitor embedding model"
echo "Use 'tail -f logs/reranker_model.log' to monitor reranker model"
echo "Use './stop_vllm_models.sh' to stop both models"