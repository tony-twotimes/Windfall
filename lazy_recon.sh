#!/bin/bash

# ==========================================
# LazyRecon - Automated Reconnaissance Tool
# Author: [Your Name/Handle]
# Usage: ./lazy_recon.sh <domain>
# ==========================================

# 1. VALIDATION: Check if a domain was provided
if [ -z "$1" ]; then
  echo "❌ Error: No target specified."
  echo "Usage: ./lazy_recon.sh <domain>"
  exit 1
fi

TARGET=$1
echo "🚀 [LazyRecon] Initiating scan against: $TARGET"

# 2. SETUP: Create a dedicated directory for results
mkdir -p $TARGET
echo "fyp📁 Created directory: $TARGET/"

# 3. ENUMERATION: Find subdomains
echo "🔍 Enumerating subdomains with Subfinder..."
subfinder -d $TARGET -o $TARGET/subs.txt > /dev/null 2>&1

# 4. PROBING: Check for live servers
echo "📡 Probing for live servers with httpx..."
cat $TARGET/subs.txt | httpx-toolkit -title -sc -o $TARGET/live.txt > /dev/null 2>&1

# 5. FILTERING: Sort interesting status codes
echo "rtd Analyzing results..."
grep "404" $TARGET/live.txt > $TARGET/potential_takeovers.txt
grep "403" $TARGET/live.txt > $TARGET/forbidden.txt
grep "200" $TARGET/live.txt > $TARGET/valid_200s.txt

# 6. REPORT
echo "✅ Scan Complete!"
echo "----------------------------------------"
echo "📊 Subdomains Found: $(wc -l < $TARGET/subs.txt)"
echo "🟢 Live Servers:     $(wc -l < $TARGET/live.txt)"
echo "🔴 404 Candidates:   $(wc -l < $TARGET/potential_takeovers.txt)"
echo "----------------------------------------"
echo "📂 Results saved in folder: $TARGET/"


