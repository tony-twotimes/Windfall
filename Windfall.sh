#!/bin/bash

# ==========================================
# WINDFALL - Automated Soft-Target Hunter
# Usage: ./windfall.sh <domain.com>
# ==========================================

# 1. SETUP & VISUALS
TARGET=$1
DATE=$(date +%Y-%m-%d)
OUT_DIR="windfall_results/${TARGET}_${DATE}"

# Colors for professional output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logo
echo -e "${YELLOW}"
echo " __      __.__                _____      _____.__  .__   "
echo "/  \    /  \__| ____   ___/ ____\____/ ____\__| |  |  "
echo "\   \/\/   /  |/    \ / __ \   __\__  \   __\|  |  |  "
echo " \        /|  |   |  \  ___/|  |  / __ \|  |  |  |  |__"
echo "  \__/\  / |__|___|  /\___  >__| (____  /__|  |__|____/"
echo "       \/          \/     \/          \/               "
echo -e "${NC}"

# Input Validation
if [ -z "$TARGET" ]; then
    echo -e "${RED}[!] Error: No target provided.${NC}"
    echo "Usage: ./windfall.sh <domain.com>"
    exit 1
fi

echo -e "${BLUE}[*] Target Locked: ${TARGET}${NC}"
echo -e "${BLUE}[*] Output Directory: ${OUT_DIR}${NC}"
mkdir -p $OUT_DIR

# ---------------------------------------------------------

echo -e "\n${GREEN}[+] PHASE 1: Harvesting Subdomains (crt.sh)...${NC}"
# Universal grabber: Get JSON -> Extract Name -> Clean Wildcards -> Remove Emails -> Sort
curl -s "https://crt.sh/?q=%25.${TARGET}&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | grep -v "@" | sort -u > $OUT_DIR/subs_clean.txt

SUB_COUNT=$(wc -l < $OUT_DIR/subs_clean.txt)
echo -e "    -> Harvested ${SUB_COUNT} unique subdomains."

# ---------------------------------------------------------

echo -e "\n${GREEN}[+] PHASE 2: Probing Live Hosts (httpx)...${NC}"
# Fast probe to see what is actually alive and what tech it runs
# -td = Tech Detect (Important for finding old IIS/Apache/Java)
cat $OUT_DIR/subs_clean.txt | httpx-toolkit -sc -title -td -fr -threads 60 -timeout 5 -silent -o $OUT_DIR/live_hosts.txt

LIVE_COUNT=$(wc -l < $OUT_DIR/live_hosts.txt)
echo -e "    -> Confirmed ${LIVE_COUNT} live hosts."

# ---------------------------------------------------------

echo -e "\n${GREEN}[+] PHASE 3: Filtering for 'Ripe' Targets...${NC}"

# THE "JUICY" LIST (Universal Weaknesses)
# We look for Staging environments, Admin panels, and known vulnerable tech
GREP_JUICY="Admin|Login|Portal|Console|Dashboard|Dev|Staging|Test|Beta|UAT|Corp|Internal|VPN|Jenkins|Grafana|Kibana|IIS|Drupal|Joomla|Apache|Tomcat|WebLogic"

# THE "ROTTEN" LIST (Noise/Hardened)
# We filter out things that usually waste time (SSO loops, generic placeholders)
GREP_IGNORE="Okta|PingIdentity|Simplesaml|Microsoft Login|Denied|Forbidden|Akamai|Cloudflare"

# The Filter Logic: Keep Juicy, Remove Rotten
grep -iE "$GREP_JUICY" $OUT_DIR/live_hosts.txt | grep -ivE "$GREP_IGNORE" > $OUT_DIR/ripe_fruit.txt

WIN_COUNT=$(wc -l < $OUT_DIR/ripe_fruit.txt)

# ---------------------------------------------------------

echo -e "\n${YELLOW}[+] PHASE 4: Nuclei Vulnerability Scan (Optional)...${NC}"
if [ $WIN_COUNT -gt 0 ]; then
    echo -e "    -> Scanning the ${WIN_COUNT} ripe targets for CVEs..."
    # We only scan the "ripe" list to save time. 
    # Tags: cve, misconfig, exposed-panels (High Impact tags)
    nuclei -l $OUT_DIR/ripe_fruit.txt -tags cve,misconfig,exposed-panels,takeover -rl 10 -o $OUT_DIR/nuclei_results.txt
else
    echo -e "${RED}[!] No ripe targets found to scan. Skipping Nuclei.${NC}"
fi

# ---------------------------------------------------------

echo -e "\n${BLUE}=============================================${NC}"
echo -e "${GREEN}Harvest Complete!${NC}"
echo -e "${BLUE}=============================================${NC}"
echo -e "Total Harvested: $SUB_COUNT"
echo -e "Live Targets:    $LIVE_COUNT"
echo -e "Ripe Fruit:      $WIN_COUNT"
echo -e ""
if [ -f "$OUT_DIR/nuclei_results.txt" ]; then
    echo -e "${YELLOW}Vulnerabilities Found:${NC}"
    cat $OUT_DIR/nuclei_results.txt | grep "\[" 
fi
echo -e "${BLUE}=============================================${NC}"

if [ $WIN_COUNT -gt 0 ]; then
    echo -e "\nSample of Ripe Targets:"
    head -n 5 $OUT_DIR/ripe_fruit.txt
fi
