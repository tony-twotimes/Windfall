# Windfall

## Overview
Windfall is a lightweight Bash automation tool designed for reconnaissance and asset discovery. It streamlines the initial phase of penetration testing and bug bounty hunting by chaining together subdomain enumeration and HTTP probing tools.

## Features
- **Automated Enumeration**: Uses tools like \`subfinder\` and \`assetfinder\` to gather subdomains.
- **Live Host Detection**: Filters for active web servers using \`httprobe\`.
- **Streamlined Output**: Saves results to organized text files for easy parsing.

## Prerequisites
Ensure the following tools are installed and in your \$PATH:
- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [Httprobe](https://github.com/tomnomnom/httprobe)

## Installation & Usage

1. **Make the script executable:**
   \`\`\`bash
   chmod +x windfall.sh
   \`\`\`

2. **Run against a target:**
   \`\`\`bash
   ./windfall.sh target.com
   \`\`\`

## Disclaimer
This tool is for authorized security testing and educational purposes only.

