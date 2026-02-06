#!/bin/bash
# install-services.sh - Install Paperless-AI as systemd services
# Run this script as root: sudo ./install-services.sh

set -e

# Configuration - adjust these paths as needed
INSTALL_DIR="/root/paperless-ai"
VENV_PATH="$INSTALL_DIR/venv"
NODE_USER="root"
DATA_DIR="$INSTALL_DIR/data"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Paperless-AI Service Installer ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (sudo ./install-services.sh)${NC}"
    exit 1
fi

# Check if installation directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Error: Installation directory not found: $INSTALL_DIR${NC}"
    echo "Please update INSTALL_DIR in this script"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo -e "${RED}Error: Python virtual environment not found: $VENV_PATH${NC}"
    echo "Please create it with: python3 -m venv $VENV_PATH"
    exit 1
fi

# Create the Python RAG service
echo -e "${YELLOW}Creating paperless-ai-rag.service...${NC}"
cat > /etc/systemd/system/paperless-ai-rag.service << EOF
[Unit]
Description=Paperless-AI RAG Python Service
Documentation=https://github.com/paperless-ngx/paperless-ai
After=network.target

[Service]
Type=simple
User=$NODE_USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$VENV_PATH/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$VENV_PATH/bin/python main.py --host 127.0.0.1 --port 3001 --initialize
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Create the Node.js service
echo -e "${YELLOW}Creating paperless-ai.service...${NC}"
cat > /etc/systemd/system/paperless-ai.service << EOF
[Unit]
Description=Paperless-AI Node.js Service
Documentation=https://github.com/paperless-ngx/paperless-ai
After=network.target paperless-ai-rag.service
Wants=paperless-ai-rag.service

[Service]
Type=simple
User=$NODE_USER
WorkingDirectory=$INSTALL_DIR
Environment="NODE_ENV=production"
Environment="RAG_SERVICE_URL=http://localhost:3001"
Environment="RAG_SERVICE_ENABLED=true"
EnvironmentFile=-$DATA_DIR/.env
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
systemctl daemon-reload

# Enable services
echo -e "${YELLOW}Enabling services...${NC}"
systemctl enable paperless-ai-rag.service
systemctl enable paperless-ai.service

echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "Services installed successfully!"
echo ""
echo -e "${YELLOW}Commands:${NC}"
echo "  Start all:    sudo systemctl start paperless-ai-rag && sudo systemctl start paperless-ai"
echo "  Stop all:     sudo systemctl stop paperless-ai && sudo systemctl stop paperless-ai-rag"
echo "  Status:       sudo systemctl status paperless-ai paperless-ai-rag"
echo "  View logs:    sudo journalctl -u paperless-ai -f"
echo "  View RAG logs: sudo journalctl -u paperless-ai-rag -f"
echo ""
echo -e "${YELLOW}To start services now:${NC}"
echo "  sudo systemctl start paperless-ai-rag"
echo "  sudo systemctl start paperless-ai"
echo ""
echo -e "${GREEN}Note: Services will start automatically on boot.${NC}"
