.PHONY: install install-semantic-routing uninstall template test

# Helm chart path
CHART_PATH := deploy/cluster/helm
RELEASE_NAME := ai-virtual-agent
NAMESPACE := $(shell kubectl config view --minify -o jsonpath='{..namespace}')

# Check if namespace is empty and use default
ifeq ($(NAMESPACE),)
NAMESPACE := default
endif

# Default install target
install:
ifeq ($(SEMANTIC_ROUTING),true)
	@$(MAKE) install-semantic-routing
else
	@echo "Installing AI Virtual Agent without semantic routing..."
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait \
		--timeout 30m
	@echo "✅ AI Virtual Agent installed successfully"
	@echo ""
	@echo "To enable semantic routing in the future, run:"
	@echo "  make install SEMANTIC_ROUTING=true"
endif

# Install with semantic routing
install-semantic-routing:
	@set -e; \
	if [ -n "$$LLM" ]; then export SEMANTIC_ROUTING_LARGE_MODEL_NAME="$$LLM"; fi; \
	if [ -n "$$LLM_URL" ]; then export SEMANTIC_ROUTING_LARGE_MODEL_URL="$$LLM_URL"; fi; \
	if [ -n "$$LLM_API_TOKEN" ]; then export SEMANTIC_ROUTING_LARGE_MODEL_API_KEY="$$LLM_API_TOKEN"; fi; \
	\
	if [ -z "$$SEMANTIC_ROUTING_LARGE_MODEL_NAME" ]; then \
		echo "ERROR: SEMANTIC_ROUTING=true requires large model configuration"; \
		echo ""; \
		echo "Missing: SEMANTIC_ROUTING_LARGE_MODEL_NAME (or LLM)"; \
		echo ""; \
		echo "Usage:"; \
		echo "  make install SEMANTIC_ROUTING=true \\"; \
		echo "    LLM=<model-name> \\"; \
		echo "    LLM_URL=<model-url> \\"; \
		echo "    LLM_API_TOKEN=<api-key>"; \
		echo ""; \
		echo "Example:"; \
		echo "  make install SEMANTIC_ROUTING=true \\"; \
		echo "    LLM=Qwen3.6-35B-A3B \\"; \
		echo "    LLM_URL=https://litemaas.rhoai.rh-aiservices-bu.com/v1 \\"; \
		echo "    LLM_API_TOKEN=sk-xxx"; \
		exit 1; \
	fi; \
	\
	if [ -z "$$SEMANTIC_ROUTING_LARGE_MODEL_URL" ]; then \
		echo "ERROR: SEMANTIC_ROUTING=true requires large model configuration"; \
		echo ""; \
		echo "Missing: SEMANTIC_ROUTING_LARGE_MODEL_URL (or LLM_URL)"; \
		echo ""; \
		echo "Usage:"; \
		echo "  make install SEMANTIC_ROUTING=true \\"; \
		echo "    LLM=<model-name> \\"; \
		echo "    LLM_URL=<model-url> \\"; \
		echo "    LLM_API_TOKEN=<api-key>"; \
		exit 1; \
	fi; \
	\
	echo "==========================================="; \
	echo "  Semantic Routing Installation"; \
	echo "==========================================="; \
	echo ""; \
	echo "Configuration:"; \
	echo "  • Small model: Llama 3.2 1B (auto-deployed locally)"; \
	echo "  • Large model: $$SEMANTIC_ROUTING_LARGE_MODEL_NAME"; \
	echo "  • Large model URL: $$SEMANTIC_ROUTING_LARGE_MODEL_URL"; \
	if [ -n "$$SEMANTIC_ROUTING_LARGE_MODEL_API_KEY" ]; then \
		echo "  • API key: <provided>"; \
	else \
		echo "  • API key: <not provided>"; \
	fi; \
	echo ""; \
	echo "Installing..."; \
	echo ""; \
	helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait \
		--timeout 30m \
		--set semanticRouting.enabled=true \
		--set semanticRouting.largeModel.name="$$SEMANTIC_ROUTING_LARGE_MODEL_NAME" \
		--set semanticRouting.largeModel.url="$$SEMANTIC_ROUTING_LARGE_MODEL_URL" \
		--set semanticRouting.largeModel.apiKey="$$SEMANTIC_ROUTING_LARGE_MODEL_API_KEY" \
		--set llama-stack.models.semantic-router.enabled=true; \
	echo ""; \
	echo "✅ AI Virtual Agent with semantic routing installed successfully"; \
	echo ""; \
	echo "The 'Semantic Router' model is now available in the agent creation UI."; \
	echo "It will automatically route between:"; \
	echo "  • Llama 3.2 1B (simple queries)"; \
	echo "  • $$SEMANTIC_ROUTING_LARGE_MODEL_NAME (complex queries)"; \
	echo ""

# Uninstall
uninstall:
	@echo "Uninstalling AI Virtual Agent..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	@echo "✅ AI Virtual Agent uninstalled successfully"

# Render templates without installing
template:
	@echo "Rendering Helm templates..."
	helm template $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE)

# Test semantic routing configuration
test-semantic-routing:
	@echo "Testing semantic routing configuration..."
	helm template $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--set semanticRouting.enabled=true \
		--set semanticRouting.largeModel.name="gpt-4" \
		--set semanticRouting.largeModel.url="https://api.openai.com/v1" \
		--set semanticRouting.largeModel.apiKey="sk-test" \
		--set llama-stack.models.semantic-router.enabled=true \
		| grep -A 20 "kind: Deployment" | head -40

# Lint the Helm chart
lint:
	@echo "Linting Helm chart..."
	helm lint $(CHART_PATH)

# Show help
help:
	@echo "AI Virtual Agent Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  install                  - Install AI Virtual Agent (default)"
	@echo "  install SEMANTIC_ROUTING=true - Install with semantic routing (interactive prompts)"
	@echo "  uninstall               - Uninstall AI Virtual Agent"
	@echo "  template                - Render Helm templates"
	@echo "  test-semantic-routing   - Test semantic routing configuration"
	@echo "  lint                    - Lint Helm chart"
	@echo "  help                    - Show this help message"
	@echo ""
	@echo "Environment Variables (for non-interactive installation):"
	@echo "  Short names:"
	@echo "    LLM            - Large model name (e.g., gpt-4, Qwen3.6-35B-A3B)"
	@echo "    LLM_URL        - Large model URL (e.g., https://api.openai.com/v1)"
	@echo "    LLM_API_TOKEN  - Large model API key/token"
	@echo ""
	@echo "  Long names (alternative):"
	@echo "    SEMANTIC_ROUTING_LARGE_MODEL_NAME    - Large model name"
	@echo "    SEMANTIC_ROUTING_LARGE_MODEL_URL     - Large model URL"
	@echo "    SEMANTIC_ROUTING_LARGE_MODEL_API_KEY - Large model API key"
	@echo ""
	@echo "Examples:"
	@echo "  make install"
	@echo "  make install SEMANTIC_ROUTING=true"
	@echo "  make install SEMANTIC_ROUTING=true LLM=gpt-4 LLM_URL=https://api.openai.com/v1 LLM_API_TOKEN=sk-xxx"
	@echo "  make install NAMESPACE=ai-virtual-agent SEMANTIC_ROUTING=true \\"
	@echo "    LLM=Qwen3.6-35B-A3B LLM_URL=https://litemaas.rhoai.rh-aiservices-bu.com/v1 \\"
	@echo "    LLM_API_TOKEN=sk-xxx"
