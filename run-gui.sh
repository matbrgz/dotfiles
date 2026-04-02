#!/bin/bash

# Setup colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Dotfiles GUI Development Environment...${NC}"

# 1. Build engines
echo -e "${YELLOW}📦 Building internal packages...${NC}"
yarn turbo build --filter="./packages/*"

# 2. Check for Rust
if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}⚠ Rust is not installed. You can still run the web version.${NC}"
    echo -e "${BLUE}🌐 Starting Web Dashboard (Vite)...${NC}"
    cd apps/gui && yarn dev:web
else
    echo -e "${GREEN}✅ Rust detected. Starting Tauri GUI...${NC}"
    cd apps/gui && yarn dev
fi
