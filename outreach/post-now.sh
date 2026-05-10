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
    
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  🐦 POST TO X/TWITTER - Target #$NUM: $INST"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Show the post text
    POST_FILE="$SCRIPT_DIR/tweets/$(printf '%02d' $NUM)-${SHORT}-post.md"
    
    # Extract just the post text (between first ## Post Text: and next ##)
    echo "📋 COPY THIS TEXT:"
    echo "────────────────────────────────────────────────────────"
    sed -n '/## Post Text:/,/## Image to Attach:/p' "$POST_FILE" | grep -v "## Post Text:" | grep -v "## Image to Attach:" | sed 's/^$//'
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo ""
    
    # Show image info
    echo "📸 ATTACH THIS IMAGE:"
    echo "   $SCRIPT_DIR/screenshots/${SHORT}.png"
    echo ""
    
    # Show tags
    echo "🏷️  TAG THESE ACCOUNTS:"
    grep "^## Tags:" "$POST_FILE" | sed 's/## Tags://'
    echo ""
    
    # Show best time
    echo "⏰ BEST TIME TO POST:"
    grep "^## Best Time to Post:" "$POST_FILE" | sed 's/## Best Time to Post://'
    echo ""
    
    # Show thread option
    echo "🧵 THREAD OPTION (for more engagement):"
    echo "────────────────────────────────────────────────────────"
    sed -n '/## Thread Option:/,/## Image to Attach:/p' "$POST_FILE" | grep -v "## Thread Option:" | grep -v "## Image to Attach:" | grep -v "^$"
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo ""
    
    # Open the screenshot
    echo "🖼️  Opening screenshot..."
    open "$SCRIPT_DIR/screenshots/${SHORT}.png"
    
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
    echo "  Screenshot: screenshots/${SHORTS[$i]}.png"
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
