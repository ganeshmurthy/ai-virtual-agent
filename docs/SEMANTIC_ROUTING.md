# Semantic Routing with Praxis + llm-d-sc

## Overview

Semantic routing intelligently routes AI agent requests between a small, fast model and a large, powerful model based on query complexity. This optimizes cost and latency while maintaining high-quality responses.

**Key Benefits:**
- 🚀 **Lower Latency**: Simple queries answered by fast 1B model locally
- 💰 **Cost Savings**: Complex queries only sent to expensive large model
- 🎯 **High Accuracy**: route-gate v0.2 classifier achieves 93.35% accuracy
- 🔧 **Flexible**: Works with any OpenAI-compatible large model (GPT-4, Claude, Azure, local vLLM)

## Architecture

```
┌────────────────────────────────────────────┐
│     AI Virtual Agent (FastAPI)             │
│  Agent with model = "semantic-router"      │
└──────────────┬─────────────────────────────┘
               │
               ↓
    ┌──────────────────────┐
    │    LlamaStack        │
    │  (orchestration)     │
    └──────────┬───────────┘
               │
               ↓
    ┌──────────────────────┐
    │  Praxis Proxy        │
    │  (port 8080)         │
    │                      │
    │  With llm-d-sc       │
    │  filter built-in     │
    └──────────┬───────────┘
               │
       Calls llm-d-sc via gRPC
       to classify complexity
               │
    ┌──────────┴───────────┐
    │                      │
    ↓                      ↓
┌─────────┐        ┌──────────────┐
│ SMALL   │        │    LARGE     │
│         │        │              │
│ Llama   │        │  User Model  │
│ 3.2 1B  │        │  (GPT-4,     │
│         │        │   Claude,    │
│ Local   │        │   Azure,     │
│ vLLM    │        │   etc.)      │
└─────────┘        └──────────────┘
```

## Components

### 1. Praxis Proxy (quay.io/ganeshmurthy/praxis-with-llm-d-sc:v0.1.0)
- High-performance Rust-based HTTP proxy
- Built with llm-d-sc filter plugin
- Routes requests based on classification header
- Admin endpoints: `/healthy`, `/ready`, `/metrics` (port 9901)

### 2. llm-d-sc Classifier (quay.io/ganeshmurthy/llm-d-sc:v0.2.0)
- Semantic classification service (gRPC on port 50051)
- Uses route-gate v0.2 binary classifier model
- 93.35% accuracy on enterprise traffic
- Model weights loaded from ModelCar init container

### 3. ModelCar (quay.io/ganeshmurthy/llm-d-sc-modelcar:route-gate-v0.2.0)
- OCI container with route-gate model weights (91.6 MB)
- Loaded via init container into llm-d-sc pod
- Separates model weights from service code

### 4. vLLM Small Model
- Llama 3.2 1B Instruct (auto-deployed locally)
- Fast inference for simple queries
- OpenAI-compatible API

### 5. Large Model
- User-provided (OpenAI, Azure, Claude, local vLLM, etc.)
- Handles complex queries requiring reasoning
- Configured via Makefile prompts

## Installation

### Quick Start (Interactive)

```bash
make install SEMANTIC_ROUTING=true
```

This will prompt you for:
1. **Large model name** (e.g., `gpt-4`, `claude-3-opus`)
2. **Large model URL** (e.g., `https://api.openai.com/v1`)
3. **API key** (optional, press Enter to skip for local models)

### Non-Interactive Installation

```bash
make install SEMANTIC_ROUTING=true \
  SEMANTIC_ROUTING_LARGE_MODEL_NAME=gpt-4 \
  SEMANTIC_ROUTING_LARGE_MODEL_URL=https://api.openai.com/v1 \
  SEMANTIC_ROUTING_LARGE_MODEL_API_KEY=sk-xxx
```

### Configuration Examples

#### OpenAI
```bash
make install SEMANTIC_ROUTING=true \
  SEMANTIC_ROUTING_LARGE_MODEL_NAME=gpt-4 \
  SEMANTIC_ROUTING_LARGE_MODEL_URL=https://api.openai.com/v1 \
  SEMANTIC_ROUTING_LARGE_MODEL_API_KEY=sk-proj-xxx
```

#### Azure OpenAI
```bash
make install SEMANTIC_ROUTING=true \
  SEMANTIC_ROUTING_LARGE_MODEL_NAME=gpt-4 \
  SEMANTIC_ROUTING_LARGE_MODEL_URL=https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT \
  SEMANTIC_ROUTING_LARGE_MODEL_API_KEY=YOUR-AZURE-KEY
```

#### Anthropic Claude
```bash
make install SEMANTIC_ROUTING=true \
  SEMANTIC_ROUTING_LARGE_MODEL_NAME=claude-3-opus \
  SEMANTIC_ROUTING_LARGE_MODEL_URL=https://api.anthropic.com/v1 \
  SEMANTIC_ROUTING_LARGE_MODEL_API_KEY=sk-ant-xxx
```

#### Local vLLM Server
```bash
make install SEMANTIC_ROUTING=true \
  SEMANTIC_ROUTING_LARGE_MODEL_NAME=llama-70b \
  SEMANTIC_ROUTING_LARGE_MODEL_URL=http://my-vllm-server:8000/v1
```

## Usage

### Creating an Agent with Semantic Routing

1. Open AI Virtual Agent UI
2. Navigate to **Agents** → **Create Agent**
3. In the **Model Provider** tab, select **"Semantic Router"**
4. Configure agent name, instructions, tools as usual
5. Save the agent

### How It Works

When you send a message to an agent configured with "Semantic Router":

1. **Request arrives** at LlamaStack
2. **LlamaStack forwards** to Praxis proxy (http://ai-virtual-agent-praxis:8080/v1)
3. **Praxis calls llm-d-sc** via gRPC to classify the prompt
4. **llm-d-sc returns** classification: `SMALL` or `LARGE`
5. **Praxis routes** to appropriate model:
   - `SMALL` → Local Llama 3.2 1B (fast, low-cost)
   - `LARGE` → Your configured large model (slower, high-quality)
6. **Response flows back** through Praxis → LlamaStack → AI Virtual Agent

### Example Queries

**Simple queries → SMALL model:**
- "What is the capital of France?"
- "Tell me a joke"
- "What's 2 + 2?"

**Complex queries → LARGE model:**
- "Analyze the economic impact of climate change on emerging markets"
- "Debug this Python code and explain the root cause"
- "Write a comprehensive project proposal for migrating to microservices"

## Monitoring

### Praxis Admin Endpoints

```bash
# Health check
kubectl port-forward svc/ai-virtual-agent-praxis 9901:9901
curl http://localhost:9901/healthy

# Readiness check
curl http://localhost:9901/ready

# Prometheus metrics
curl http://localhost:9901/metrics
```

### LlamaStack Model Registration

```bash
# Verify semantic-router model is registered
kubectl exec -it deployment/llamastack -- curl http://localhost:8321/v1/models
```

You should see:
```json
{
  "data": [
    {
      "id": "semantic-router",
      "provider_id": "semantic-router",
      "model_type": "llm"
    }
  ]
}
```

## Troubleshooting

### Semantic Router Not Available in UI

**Problem**: "Semantic Router" doesn't appear in the model selection dropdown.

**Solution**:
1. Verify semantic routing is enabled:
   ```bash
   helm get values ai-virtual-agent | grep semanticRouting -A 5
   ```
2. Check LlamaStack model registration:
   ```bash
   kubectl logs deployment/llamastack | grep semantic-router
   ```
3. Verify llama-stack.models.semantic-router.enabled is true:
   ```bash
   helm get values ai-virtual-agent | grep -A 3 "models:"
   ```

### Praxis Pod CrashLoopBackOff

**Problem**: Praxis pod fails to start.

**Solution**:
1. Check logs:
   ```bash
   kubectl logs deployment/ai-virtual-agent-praxis
   ```
2. Verify ConfigMap is correct:
   ```bash
   kubectl get configmap ai-virtual-agent-praxis-config -o yaml
   ```
3. Check if llm-d-sc service is accessible:
   ```bash
   kubectl exec -it deployment/ai-virtual-agent-praxis -- nc -zv ai-virtual-agent-llm-d-sc 50051
   ```

### llm-d-sc Pod Not Ready

**Problem**: llm-d-sc classifier pod stuck in ContainerCreating or not ready.

**Solution**:
1. Check init container (model-loader):
   ```bash
   kubectl logs deployment/ai-virtual-agent-llm-d-sc -c model-loader
   ```
2. Verify ModelCar image is accessible:
   ```bash
   kubectl get pods -l app.kubernetes.io/component=semantic-routing-classifier -o yaml | grep -A 2 "initContainers:"
   ```
3. Check gRPC health probe:
   ```bash
   kubectl exec -it deployment/ai-virtual-agent-llm-d-sc -- grpc_health_probe -addr=:50051
   ```

### vLLM Small Model Out of Memory

**Problem**: vLLM small model pod gets OOMKilled.

**Solution**:
1. Increase memory limits in values.yaml:
   ```yaml
   semanticRouting:
     smallModel:
       resources:
         limits:
           memory: "16Gi"  # Increase from 8Gi
   ```
2. Or reduce model context length:
   ```yaml
   semanticRouting:
     smallModel:
       args:
         - --max-model-len
         - "4096"  # Reduce from 8192
   ```

### Routing to Wrong Model

**Problem**: Simple queries going to large model or complex queries to small model.

**Solution**:
1. Check Praxis logs for classification results:
   ```bash
   kubectl logs deployment/ai-virtual-agent-praxis | grep "X-LLM-D-Triage"
   ```
2. Test llm-d-sc directly:
   ```bash
   kubectl port-forward svc/ai-virtual-agent-llm-d-sc 50051:50051
   # Use grpcurl or similar to test classification
   ```
3. Verify Praxis routing rules in ConfigMap:
   ```bash
   kubectl get configmap ai-virtual-agent-praxis-config -o yaml | grep -A 20 "routes:"
   ```

## Advanced Configuration

### Custom Resource Limits

```yaml
# values.yaml
semanticRouting:
  enabled: true
  
  praxis:
    resources:
      requests:
        cpu: "200m"
        memory: "256Mi"
      limits:
        cpu: "1000m"
        memory: "512Mi"
  
  classifier:
    resources:
      requests:
        cpu: "1000m"
        memory: "2Gi"
      limits:
        cpu: "2000m"
        memory: "4Gi"
  
  smallModel:
    resources:
      requests:
        cpu: "4"
        memory: "8Gi"
      limits:
        cpu: "8"
        memory: "16Gi"
```

### Custom vLLM Arguments

```yaml
# values.yaml
semanticRouting:
  smallModel:
    args:
      - --max-model-len
      - "16384"  # Larger context window
      - --max-num-seqs
      - "32"     # More concurrent sequences
      - --dtype
      - "bfloat16"
      - --gpu-memory-utilization
      - "0.9"    # Use more GPU memory
```

### Using Different Small Model

```yaml
# values.yaml
semanticRouting:
  smallModel:
    name: llama-3.2-3b
    modelId: meta-llama/Llama-3.2-3B-Instruct
    resources:
      limits:
        memory: "16Gi"  # Larger model needs more memory
```

## Performance Characteristics

### Latency

- **Small model (Llama 3.2 1B)**: ~100-500ms (local inference)
- **Large model**: Depends on provider (1-5s typical for cloud APIs)
- **Classification overhead**: ~50-100ms (llm-d-sc via gRPC)
- **Praxis routing overhead**: <10ms

### Accuracy

- **route-gate v0.2 classifier**: 93.35% accuracy on enterprise traffic
- **False positives** (simple→large): Wastes cost but maintains quality
- **False negatives** (complex→small): May produce lower quality responses (~6.65% of queries)

### Resource Usage

| Component | CPU | Memory | Notes |
|-----------|-----|--------|-------|
| Praxis | 100-500m | 128-256Mi | Lightweight proxy |
| llm-d-sc | 500-1000m | 1-2Gi | Model inference |
| vLLM Small | 2-4 cores | 4-8Gi | Full LLM inference |

## Uninstallation

```bash
make uninstall
```

This removes all AI Virtual Agent components including semantic routing.

## References

- **Praxis**: https://github.com/praxis-proxy/praxis
- **llm-d-semantic-classifier**: https://github.com/RHEcosystemAppEng/llm-d-semantic-classifier
- **llm-d-sc-praxis-filter**: https://github.com/cnuland/llm-d-sc-praxis-filter
- **route-gate v0.2 models**: https://github.com/cnuland/llm-d-sc-route-gate
- **vLLM**: https://github.com/vllm-project/vllm
- **LlamaStack**: https://github.com/meta-llama/llama-stack

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Praxis, llm-d-sc, and vLLM logs
3. Open an issue at https://github.com/ganeshmurthy/ai-virtual-agent/issues
