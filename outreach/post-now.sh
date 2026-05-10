#!/bin/bash

# ==========================================
#  🚀 POST TO X/TWITTER - ONE CLICK
# ==========================================
# Usage:
#   ./post-now.sh 1     - Show post for target #1 (BlackRock)
#   ./post-now.sh all   - Show all posts
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTITUTIONS=(
  "1: BlackRock - BUIDL"
  "2: Franklin Templeton - FOBXX"
  "3: Goldman Sachs - GS DAP"
  "4: J.P. Morgan - Onyx"
  "5: HSBC - Orion"
  "6: Citi - Digital Assets"
  "7: BNY Mellon - Digital Custody"
  "8: Fidelity - Digital Assets"
  "9: Siemens - Corporate Treasury"
  "10: World Bank - bond-i"
)

SHORTS=(
  "blackrock-buidl"
  "franklin-templeton-fobxx"
  "goldman-sachs-dap"
  "jp-morgan-onyx"
  "hsbc-orion"
  "citi-digital-assets"
  "bny-mellon-digital-custody"
  "fidelity-digital-assets"
  "siemens-corporate-treasury"
  "world-bank-bond-i"
)

SCREENSHOT_MAP=(
  "blackrock"
  "franklin-templeton"
  "goldman-sachs"
  "jpmorgan"
  "hsbc"
  "citi"
  "bny-mellon"
  "fidelity"
  "siemens"
  "world-bank"
)

show_post() {
  NUM=$1
  IDX=$((NUM - 1))
  
  if [ $NUM -ge 1 ] && [ $NUM -le 10 ]; then
    INST="${INSTITUTIONS[$IDX]}"
    SHORT="${SHORTS[$IDX]}"
    SCREEN="${SCREENSHOT_MAP[$IDX]}"
    POST_FILE="$SCRIPT_DIR/tweets/$(printf '%02d' $NUM)-${SHORT}-post.md"
    
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  🐦 POST TO X/TWITTER - Target #$NUM: $INST"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Read the file and extract sections
    content=$(cat "$POST_FILE")
    
    # Extract post text (between "## Post Text:" and "---")
    post_text=$(echo "$content" | sed -n '/^## Post Text:/,/^---/p' | sed '1d;$d')
    
    # Extract tags (next line after ## Tags:)
    tags=$(echo "$content" | grep -A1 "^## Tags:" | tail -1)
    
    # Extract best time (next line after ## Best Time to Post:)
    best_time=$(echo "$content" | grep -A1 "^## Best Time to Post:" | tail -1)
    
    # Extract thread option
    thread=$(echo "$content" | sed -n '/^## Thread Option:/,/^## Image to Attach:/p' | sed '1d;$d')
    
    echo "📋 COPY THIS TEXT:"
    echo "────────────────────────────────────────────────────────"
    echo "$post_text"
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo ""
    
    echo "📸 ATTACH THIS IMAGE:"
    echo "   $SCRIPT_DIR/screenshots/${SCREEN}.png"
    echo ""
    
    echo "🏷️  TAG THESE ACCOUNTS:"
    echo "   $tags"
    echo ""
    
    echo "⏰ BEST TIME TO POST:"
    echo "   $best_time"
    echo ""
    
    echo "🧵 THREAD OPTION (for more engagement):"
    echo "────────────────────────────────────────────────────────"
    echo "$thread"
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo ""
    
    # Open the screenshot
    echo "🖼️  Opening screenshot..."
    open "$SCRIPT_DIR/screenshots/${SCREEN}.png" 2>/dev/null || echo "     (screenshot file exists)"
    
    echo ""
    echo "✅ Ready to post! Open X/Twitter and paste the text above."
    echo "   Attach the screenshot that just opened."
    echo ""
    
  else
    echo "❌ Invalid target number. Use 1-10."
    echo ""
    echo "Available targets:"
    for inst in "${INSTITUTIONS[@]}"; do
      echo "  $inst"
    done
  fi
}

show_all() {
  clear
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  🚀 ALL POSTS READY TO SHIP"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
  
  for i in "${!INSTITUTIONS[@]}"; do
    NUM=$((i + 1))
    echo "  Target #$NUM: ${INSTITUTIONS[$i]}"
    echo "  ──────────────────────────────────────"
    echo "  Post: ./post-now.sh $NUM"
    echo "  Screenshot: screenshots/${SCREENSHOT_MAP[$i]}.png"
    echo ""
  done
  
  echo "─────────────────────────────────────────────"
  echo "  🚀 Start posting! Run:"
  echo "  ./post-now.sh 1   (for BlackRock)"
  echo "  ./post-now.sh 2   (for Franklin Templeton)"
  echo "  ..."
  echo "  ./post-now.sh 10  (for World Bank)"
  echo "─────────────────────────────────────────────"
}

case "${1:-}" in
  all)
    show_all
    ;;
  *)
    show_post "${1:-}"
    ;;
esac
