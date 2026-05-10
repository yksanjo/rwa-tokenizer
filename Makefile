.PHONY: help setup test deploy iterate generate

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install all dependencies
	@echo "📦 Installing dependencies..."
	cd contracts && npm install
	cd frontend && npm install
	@echo "✅ Setup complete!"

test: ## Run all tests
	@echo "🧪 Running tests..."
	cd contracts && npx hardhat test
	@echo "✅ Tests complete!"

deploy: ## Deploy to network (usage: make deploy NETWORK=sepolia)
	@echo "🚀 Deploying to $(NETWORK)..."
	cd contracts && npx hardhat run scripts/deploy.js --network $(NETWORK)
	@echo "✅ Deployment complete!"

iterate: ## Start rapid iteration loop
	@echo "🔄 Starting iteration loop..."
	./scripts/iterate.sh

generate: ## Generate code from prompt (usage: make generate PROMPT=prompts/contract-generator.md OUT=contracts/src)
	@echo "🤖 Generating code from $(PROMPT)..."
	./scripts/deepseek-generate.sh $(PROMPT) $(OUT)
	@echo "✅ Generation complete!"

frontend: ## Start frontend dev server
	@echo "🌐 Starting frontend..."
	cd frontend && npm run dev

quick-start: ## Full quick start: setup -> test -> deploy -> frontend
	@echo "🚀 RWA Tokenizer - Quick Start"
	@echo "==============================="
	@echo ""
	@echo "Step 1: Setup"
	@echo "  make setup"
	@echo ""
	@echo "Step 2: Test"
	@echo "  make test"
	@echo ""
	@echo "Step 3: Deploy"
	@echo "  make deploy NETWORK=sepolia"
	@echo ""
	@echo "Step 4: Start frontend"
	@echo "  make frontend"
	@echo ""
	@echo "Step 5: Iterate"
	@echo "  make iterate"
	@echo ""
	@echo "Or use DeepSeek to generate more:"
	@echo "  make generate PROMPT=prompts/api-generator.md OUT=api"
