#!/bin/bash
# uninstall-services.sh - Remove Paperless-AI systemd services
# Run this script as root: sudo ./uninstall-services.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Paperless-AI Service Uninstaller ===${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

# Stop services
echo -e "${YELLOW}Stopping services...${NC}"
systemctl stop paperless-ai.service 2>/dev/null || true
systemctl stop paperless-ai-rag.service 2>/dev/null || true

# Disable services
echo -e "${YELLOW}Disabling services...${NC}"
systemctl disable paperless-ai.service 2>/dev/null || true
systemctl disable paperless-ai-rag.service 2>/dev/null || true

# Remove service files
echo -e "${YELLOW}Removing service files...${NC}"
rm -f /etc/systemd/system/paperless-ai.service
rm -f /etc/systemd/system/paperless-ai-rag.service

# Reload systemd
systemctl daemon-reload

echo -e "${GREEN}Services removed successfully!${NC}"
