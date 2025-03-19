#!/bin/bash

# 共通ユーティリティの読み込み
source "$(dirname "$0")/utils.sh"

# サービスの起動
echo "サービスを起動しています..."
if ! docker compose up -d; then
    echo -e "${RED}エラー: サービスの起動に失敗しました${NC}"
    exit 1
fi

echo "Kongデータベースの準備ができるまで待機中..."
# データベースの準備ができるまで待機
max_retries=30
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if docker compose exec -T kong-database pg_isready -U kong; then
        echo "Kongデータベースの準備が完了しました"
        break
    fi
    retry_count=$((retry_count + 1))
    echo "データベース接続を待機中... ($retry_count/$max_retries)"
    sleep 2
done

if [ $retry_count -eq $max_retries ]; then
    echo -e "${RED}エラー: データベースの準備に失敗しました${NC}"
    exit 1
fi

echo "Kongのマイグレーションを実行中..."
if ! docker compose exec -T kong kong migrations bootstrap; then
    echo -e "${RED}エラー: Kongのマイグレーションに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}サービスを起動しました${NC}"