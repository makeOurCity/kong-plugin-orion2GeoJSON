#!/bin/bash

# 共通ユーティリティの読み込み
source "$(dirname "$0")/utils.sh"

# サービスの起動
echo "サービスを起動しています..."
if ! docker compose up -d; then
    echo -e "${RED}エラー: サービスの起動に失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}サービスを起動しました${NC}"