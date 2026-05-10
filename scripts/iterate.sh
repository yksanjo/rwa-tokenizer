#!/bin/bash
# Rapid iteration loop for RWA Tokenizer
# Runs: test -> analyze -> improve -> repeat
# Usage: ./scripts/iterate.sh

set -e

echo "🔄 RWA Tokenizer - Rapid Iteration Loop"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))
  echo ""
  echo -e "${YELLOW}=== Iteration $ITERATION ===${NC}"
  echo ""

  # 1. Run tests
  echo -e "${YELLOW}🧪 Running tests...${NC}"
  cd contracts
  
  TEST_OUTPUT=$(forge test 2>&1) || true
  
  if echo "$TEST_OUTPUT" | grep -q "FAIL"; then
    echo -e "${RED}❌ Tests failed!${NC}"
    echo "$TEST_OUTPUT" | grep -A 5 "FAIL"
    
    # Extract error for DeepSeek
    ERROR=$(echo "$TEST_OUTPUT" | grep -A 10 "FAIL" | head -20)
    
    echo ""
    echo -e "${YELLOW}🤖 Asking DeepSeek to fix...${NC}"
    
    # Call DeepSeek to fix
    FIX=$(curl -s https://api.deepseek.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
      -d '{
        "model": "deepseek-chat",
        "messages": [
          {
            "role": "system",
            "content": "You are a Solidity expert. Analyze the test failure and provide the fix."
          },
          {
            "role": "user",
            "content": "Test failed with error:\n'"$ERROR"'\n\nProvide the exact code fix needed."
          }
        ],
        "temperature": 0.1,
        "max_tokens": 1000
      }')
    
    echo "$FIX" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data['choices'][0]['message']['content'])
" 2>/dev/null || echo "Could not parse fix"
    
  else
    echo -e "${GREEN}✅ All tests passed!${NC}"
  fi
  
  cd ..
  
  # 2. Wait for file changes
  echo ""
  echo -e "${YELLOW}👀 Watching for changes (Ctrl+C to stop)...${NC}"
  
  # Watch for changes in contracts and frontend
  fswatch -o contracts/src frontend/app frontend/components 2>/dev/null || \
  inotifywait -r -e modify contracts/src frontend/app frontend/components 2>/dev/null || {
    echo "No file watcher available. Press Enter to re-run tests, or Ctrl+C to exit."
    read
  }
done
