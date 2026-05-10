#!/bin/bash

# ==========================================
#  🚀 RWA Tokenizer - Outreach Automation
# ==========================================
# This script helps you send cold emails and
# post tweets to target institutions.
#
# Usage:
#   ./outreach.sh list          - Show all targets
#   ./outreach.sh email <num>   - Open email template for target #N
#   ./outreach.sh tweet <num>   - Open tweet template for target #N
#   ./outreach.sh screenshot <num> - Open screenshot for target #N
#   ./outreach.sh track         - Open tracking spreadsheet
#   ./outreach.sh all           - Show everything for all targets
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

show_list() {
  echo ""
  echo "  🎯 TARGET INSTITUTIONS"
  echo "  ======================"
  for inst in "${INSTITUTIONS[@]}"; do
    echo "    $inst"
  done
  echo ""
}

show_all() {
  echo ""
  echo "  =========================================="
  echo "   🚀 RWA TOKENIZER - COMPLETE OUTREACH KIT"
  echo "  =========================================="
  echo ""
  
  for i in "${!INSTITUTIONS[@]}"; do
    NUM=$((i + 1))
    echo "  ────────────────────────────────────────"
    echo "  📍 TARGET #$NUM: ${INSTITUTIONS[$i]}"
    echo "  ────────────────────────────────────────"
    echo "  📧 Email:   $SCRIPT_DIR/emails/$(printf '%02d' $NUM)-${SHORTS[$i]}.md"
    echo "  🐦 Tweet:   $SCRIPT_DIR/tweets/$(printf '%02d' $NUM)-${SHORTS[$i]}.md"
    echo "  📸 Screenshot: $SCRIPT_DIR/screenshots/${SHORTS[$i]}.png"
    echo ""
  done
  
  echo "  ────────────────────────────────────────"
  echo "  📊 Tracker: $SCRIPT_DIR/tracking/outreach-tracker.csv"
  echo "  ────────────────────────────────────────"
  echo ""
  echo "  🚀 Ready to ship! Start with target #1:"
  echo "     ./outreach.sh email 1"
  echo "     ./outreach.sh tweet 1"
  echo "     ./outreach.sh screenshot 1"
  echo ""
}

open_email() {
  NUM=$1
  IDX=$((NUM - 1))
  if [ $NUM -ge 1 ] && [ $NUM -le 10 ]; then
    FILE="$SCRIPT_DIR/emails/$(printf '%02d' $NUM)-${SHORTS[$IDX]}.md"
    echo "📧 Opening email template for ${INSTITUTIONS[$IDX]}..."
    echo ""
    cat "$FILE"
    echo ""
    echo "────────────────────────────────────"
    echo "Copy the email above and send to the"
    echo "institution's team. Good luck! 🚀"
  else
    echo "❌ Invalid target number. Use 1-10."
    show_list
  fi
}

open_tweet() {
  NUM=$1
  IDX=$((NUM - 1))
  if [ $NUM -ge 1 ] && [ $NUM -le 10 ]; then
    FILE="$SCRIPT_DIR/tweets/$(printf '%02d' $NUM)-${SHORTS[$IDX]}.md"
    echo "🐦 Opening tweet template for ${INSTITUTIONS[$IDX]}..."
    echo ""
    cat "$FILE"
    echo ""
    echo "────────────────────────────────────"
    echo "Post this on X/Twitter with the"
    echo "screenshot attached! 🚀"
  else
    echo "❌ Invalid target number. Use 1-10."
    show_list
  fi
}

open_screenshot() {
  NUM=$1
  IDX=$((NUM - 1))
  if [ $NUM -ge 1 ] && [ $NUM -le 10 ]; then
    FILE="$SCRIPT_DIR/screenshots/${SHORTS[$IDX]}.png"
    echo "📸 Opening screenshot for ${INSTITUTIONS[$IDX]}..."
    open "$FILE"
    echo "Screenshot opened!"
  else
    echo "❌ Invalid target number. Use 1-10."
    show_list
  fi
}

open_tracker() {
  echo "📊 Opening tracking spreadsheet..."
  open "$SCRIPT_DIR/tracking/outreach-tracker.csv"
}

case "${1:-}" in
  list)
    show_list
    ;;
  email)
    open_email "${2:-}"
    ;;
  tweet)
    open_tweet "${2:-}"
    ;;
  screenshot)
    open_screenshot "${2:-}"
    ;;
  track)
    open_tracker
    ;;
  all)
    show_all
    ;;
  *)
    echo ""
    echo "  🚀 RWA Tokenizer - Outreach Automation"
    echo "  ======================================"
    echo ""
    echo "  Usage:"
    echo "    ./outreach.sh list          - Show all targets"
    echo "    ./outreach.sh email <num>   - Open email template"
    echo "    ./outreach.sh tweet <num>   - Open tweet template"
    echo "    ./outreach.sh screenshot <num> - Open screenshot"
    echo "    ./outreach.sh track         - Open tracker"
    echo "    ./outreach.sh all           - Show everything"
    echo ""
    show_list
    ;;
esac
