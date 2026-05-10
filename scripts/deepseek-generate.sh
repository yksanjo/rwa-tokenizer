#!/bin/bash
# DeepSeek Code Generator for RWA Tokenization
# Usage: ./scripts/deepseek-generate.sh <prompt-file> <output-dir>

set -e

DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-$DEEPSEEK_API_KEY}"
PROMPT_FILE="$1"
OUTPUT_DIR="$2"

if [ -z "$PROMPT_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: ./scripts/deepseek-generate.sh <prompt-file> <output-dir>"
  echo ""
  echo "Examples:"
  echo "  ./scripts/deepseek-generate.sh prompts/contract-generator.md contracts/src"
  echo "  ./scripts/deepseek-generate.sh prompts/api-generator.md api"
  echo "  ./scripts/deepseek-generate.sh prompts/frontend-generator.md frontend"
  exit 1
fi

if [ -z "$DEEPSEEK_API_KEY" ]; then
  echo "Error: DEEPSEEK_API_KEY not set"
  echo "Set it: export DEEPSEEK_API_KEY='your-key-here'"
  exit 1
fi

echo "🚀 Generating code from: $PROMPT_FILE"
echo "📁 Output to: $OUTPUT_DIR"
echo ""

# Read the prompt
PROMPT=$(cat "$PROMPT_FILE")

# Call DeepSeek API
echo "🤖 Calling DeepSeek API..."
RESPONSE=$(curl -s https://api.deepseek.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  -d '{
    "model": "deepseek-chat",
    "messages": [
      {
        "role": "system",
        "content": "You are an expert Solidity and full-stack developer. Generate production-ready code for RWA tokenization. Output ONLY the code files, no explanations."
      },
      {
        "role": "user",
        "content": '"$(echo "$PROMPT" | jq -Rs .)"'
      }
    ],
    "temperature": 0.3,
    "max_tokens": 4000
  }')

# Extract code blocks and save files
echo "📝 Extracting and saving generated code..."
echo "$RESPONSE" | python3 -c "
import json, re, os, sys

response = json.load(sys.stdin)
content = response['choices'][0]['message']['content']

# Extract code blocks with filenames
pattern = r'```(\w+)\n(?:.*?\n)?(.*?)```'
matches = re.findall(pattern, content, re.DOTALL)

output_dir = '$OUTPUT_DIR'
os.makedirs(output_dir, exist_ok=True)

for lang, code in matches:
    # Try to find filename in the code block header
    lines = code.strip().split('\n')
    filename = None
    
    # Check if first line looks like a filename
    if lines and ('/' in lines[0] or lines[0].endswith('.sol') or lines[0].endswith('.ts') or lines[0].endswith('.py')):
        filename = lines[0].strip()
        code = '\n'.join(lines[1:])
    
    if filename:
        filepath = os.path.join(output_dir, filename)
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(code.strip())
        print(f'  ✅ Saved: {filepath}')

print('\n✨ Generation complete!')
"

echo ""
echo "✅ Done! Generated files are in: $OUTPUT_DIR"
