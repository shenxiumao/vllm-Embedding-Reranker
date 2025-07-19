# Embedding & Reranker Proxy Service

一个专门为Qwen3 Embedding和Reranker模型设计的高性能代理服务系统。

## 📋 项目概述

本项目提供了一套完整的解决方案，用于部署和管理Qwen3-Embedding-0.6B和Qwen3-Reranker-0.6B模型服务，包括：

- **代理服务器**：统一的API接口和认证管理
- **模型管理脚本**：自动化的模型启动、停止和状态监控
- **高并发优化**：支持大规模并发请求处理

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTP Requests
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Embedding & Reranker Proxy                    │
│                    (Port 2048)                             │
│  ┌─────────────────┐  ┌─────────────────┐                 │
│  │   API Gateway   │  │  Authentication │                 │
│  │   Rate Limiting │  │   Load Balancer │                 │
│  └─────────────────┘  └─────────────────┘                 │
└─────────────────────┬───────────────────┬───────────────────┘
                      │                   │
                      ▼                   ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│    Qwen3-Embedding-0.6B     │ │    Qwen3-Reranker-0.6B     │
│        (GPU 1)              │ │        (GPU 0)              │
│       Port 8000             │ │       Port 8001             │
│     Embedding Task          │ │      Scoring Task           │
└─────────────────────────────┘ └─────────────────────────────┘
```

## 📁 文件结构

```
ER/
├── embedding_reranker_proxy.py    # 主代理服务器
├── start_vllm_models.sh           # 模型启动脚本
├── stop_vllm_models.sh            # 模型停止脚本
├── check_models_status.sh         # 状态检查脚本
├── README.md                      # 项目文档
├── logs/                          # 日志目录（自动创建）
│   ├── embedding_model.log        # Embedding模型日志
│   ├── reranker_model.log         # Reranker模型日志
│   ├── embedding.pid              # Embedding进程PID
│   └── reranker.pid               # Reranker进程PID
└── er_api_keys.json              # API密钥配置文件（自动生成）
```

## 🚀 快速开始

### 1. 环境准备

确保系统已安装以下依赖：

```bash
# Python依赖
pip install fastapi uvicorn httpx pydantic

# vLLM安装
pip install vllm

# 系统工具
sudo apt-get install curl
```

### 2. 模型部署

确保模型文件位于正确路径：
- Embedding模型：`/mnt/workspace/model/Qwen/Qwen3-Embedding-0.6B`
- Reranker模型：`/mnt/workspace/model/Qwen/Qwen3-Reranker-0.6B`

### 3. 启动服务

```bash
# 进入项目目录
cd /root/data/vllm-serve/ER

# 添加执行权限
chmod +x *.sh

# 启动vLLM模型服务
./start_vllm_models.sh

# 等待模型加载完成后，启动代理服务器
python embedding_reranker_proxy.py
```

### 4. 验证部署

```bash
# 检查模型状态
./check_models_status.sh

# 测试API接口
curl http://localhost:2048/health
```

## 🔧 配置说明

### 模型配置

| 模型 | GPU | 端口 | 任务类型 | 内存利用率 |
|------|-----|------|----------|------------|
| Qwen3-Embedding-0.6B | GPU 1 | 8000 | embed | 90% |
| Qwen3-Reranker-0.6B | GPU 0 | 8001 | score | 97% |

### 代理服务器配置

- **端口**：2048
- **工作进程**：64
- **并发限制**：500
- **速率限制**：100次/分钟
- **超时设置**：600秒

### API密钥管理

系统会自动生成API密钥并保存在`er_api_keys.json`文件中。首次启动时会在日志中显示生成的密钥。

## 📚 API使用指南

### 认证方式

支持两种认证方式：

1. **请求头认证**：
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:2048/v1/models
   ```

2. **查询参数认证**：
   ```bash
   curl "http://localhost:2048/v1/models?api_key=YOUR_API_KEY"
   ```

### 主要端点

#### 1. 获取模型列表
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     http://localhost:2048/v1/models
```

#### 2. 文本嵌入
```bash
curl -X POST \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "Qwen3-Embedding-0.6B",
       "input": "Hello, world!"
     }' \
     http://localhost:2048/v1/embeddings
```

#### 3. 文本重排序
```bash
curl -X POST \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "Qwen3-Reranker-0.6B",
       "query": "What is AI?",
       "documents": ["AI is artificial intelligence", "AI helps humans"]
     }' \
     http://localhost:2048/v1/rerank
```

#### 4. 健康检查
```bash
curl http://localhost:2048/health
```

## 🛠️ 运维管理

### 启动服务
```bash
./start_vllm_models.sh    # 启动vLLM模型
python embedding_reranker_proxy.py  # 启动代理服务
```

### 停止服务
```bash
./stop_vllm_models.sh     # 停止vLLM模型
# Ctrl+C 停止代理服务
```

### 状态监控
```bash
./check_models_status.sh  # 检查所有服务状态
```

### 日志查看
```bash
# 查看Embedding模型日志
tail -f logs/embedding_model.log

# 查看Reranker模型日志
tail -f logs/reranker_model.log

# 查看代理服务日志
tail -f embedding_reranker_proxy.log
```

## ⚡ 性能优化

### 并发性能
- **64个工作进程**：充分利用多核CPU
- **500并发连接**：支持大规模并发请求
- **连接池优化**：减少连接开销，提高响应速度

### GPU优化
- **GPU分离部署**：避免显存竞争
- **高内存利用率**：最大化GPU资源使用
- **优化的块大小**：平衡内存和性能

### 网络优化
- **Keep-Alive连接**：减少连接建立开销
- **HTTP/2支持**：提高传输效率
- **智能负载均衡**：自动路由到最优后端

## 🔍 故障排除

### 常见问题

1. **429 Too Many Requests**
   - 检查速率限制配置
   - 增加`rate_limit`值
   - 使用多个API密钥分散请求

2. **503 Service Unavailable**
   - 检查后端模型服务状态
   - 验证GPU资源可用性
   - 查看模型日志排查启动问题

3. **504 Gateway Timeout**
   - 增加超时时间配置
   - 检查网络连接
   - 优化模型推理性能

### 调试命令

```bash
# 检查GPU状态
nvidia-smi

# 检查端口占用
netstat -tlnp | grep -E '(8000|8001|2048)'

# 检查进程状态
ps aux | grep vllm
ps aux | grep embedding_reranker_proxy

# 测试模型API
curl http://localhost:8000/health
curl http://localhost:8001/health
```

## 📈 监控指标

### 系统指标
- CPU使用率
- 内存使用率
- GPU利用率和显存使用
- 网络I/O

### 应用指标
- 请求响应时间
- 请求成功率
- 并发连接数
- API调用频率

### 业务指标
- 嵌入向量生成速度
- 重排序准确性
- 用户满意度

## 🔒 安全考虑

- **API密钥认证**：防止未授权访问
- **速率限制**：防止API滥用
- **日志记录**：完整的访问审计
- **HTTPS支持**：数据传输加密（生产环境推荐）

## 📞 技术支持

如遇到问题，请按以下步骤排查：

1. 查看相关日志文件
2. 运行状态检查脚本
3. 检查系统资源使用情况
4. 参考故障排除章节

## 📄 许可证

本项目遵循相应的开源许可证。使用前请确保遵守相关模型的使用条款。

---

**注意**：本文档基于当前配置编写，实际部署时请根据具体环境调整相关参数。