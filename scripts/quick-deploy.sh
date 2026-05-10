#!/bin/bash
# Quick deploy script for RWA Tokenization stack
# Usage: ./scripts/quick-deploy.sh [network]

set -e

NETWORK="${1:-sepolia}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="deploy_${NETWORK}_${TIMESTAMP}.log"

echo "🚀 RWA Tokenizer - Quick Deploy"
echo "================================"
echo "Network: $NETWORK"
echo "Time: $(date)"
echo ""

# 1. Check environment
echo "📋 Checking environment..."
if [ ! -f ".env" ]; then
  echo "  ⚠️  No .env file found. Creating from template..."
  cat > .env << EOF
# Required
PRIVATE_KEY=your-private-key-here
DEEPSEEK_API_KEY=your-deepseek-api-key
ETHERSCAN_API_KEY=your-etherscan-api-key

# Optional (defaults shown)
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-key
WALLET_CONNECT_PROJECT_ID=your-walletconnect-id
EOF
  echo "  ✅ Created .env template - EDIT IT with your keys!"
  exit 1
fi

source .env

# 2. Install dependencies
echo ""
echo "📦 Installing dependencies..."
cd contracts
npm install 2>&1 | tail -1
cd ../frontend
npm install 2>&1 | tail -1
cd ..

# 3. Compile contracts
echo ""
echo "🔨 Compiling contracts..."
cd contracts
npx hardhat compile 2>&1 | tail -5
cd ..

# 4. Run tests
echo ""
echo "🧪 Running tests..."
cd contracts
npx hardhat test 2>&1 | tail -10
cd ..

# 5. Deploy contracts
echo ""
echo "📡 Deploying to $NETWORK..."
cd contracts
npx hardhat run scripts/deploy.js --network $NETWORK 2>&1 | tee "../$LOG_FILE"
cd ..

# 6. Extract deployed address
PROXY_ADDRESS=$(grep "PROXY=" "$LOG_FILE" | cut -d'=' -f2)
echo ""
echo "✅ Contract deployed at: $PROXY_ADDRESS"

# 7. Update frontend config
echo ""
echo "🔧 Updating frontend config..."
sed -i '' "s/11155111: \"0x\.\.\.\"/11155111: \"$PROXY_ADDRESS\"/" frontend/lib/contracts.ts

# 8. Build frontend
echo ""
echo "🏗️  Building frontend..."
cd frontend
npm run build 2>&1 | tail -5
cd ..

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo "Contract: $PROXY_ADDRESS"
echo "Network:  $NETWORK"
echo "Log:      $LOG_FILE"
echo ""
echo "Next steps:"
echo "  1. Verify contract on Etherscan"
echo "  2. Deploy frontend: cd frontend && npm run deploy"
echo "  3. Set up roles: AGENT, VERIFIER"
echo "  4. Whitelist investors"
echo "  5. Activate asset"
