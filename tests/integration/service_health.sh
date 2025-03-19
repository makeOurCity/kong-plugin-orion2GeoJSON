#!/bin/bash

# 共通ユーティリティの読み込み
source "$(dirname "$0")/utils.sh"

# コンテナの状態を確認する関数
check_container() {
    local service=$1
    if ! docker compose ps $service --format json | grep -q "running"; then
        echo -e "${RED}エラー: $serviceが正常に起動していません${NC}"
        docker compose logs $service
        return 1
    fi
    echo -e "${GREEN}✓ $serviceが正常に動作しています${NC}"
    return 0
}

# サービスの起動
echo "サービスを起動しています..."
if ! docker compose up -d; then
    echo -e "${RED}エラー: サービスの起動に失敗しました${NC}"
    cleanup 1
fi

# サービスの状態確認
echo "サービスの状態を確認しています..."
sleep 5  # サービスの起動を待つ

# 各サービスの確認
services=("kong" "orion" "mongo")
failed=false

for service in "${services[@]}"; do
    if ! check_container $service; then
        failed=true
    fi
done

if [ "$failed" = true ]; then
    echo -e "${RED}テストに失敗しました${NC}"
    cleanup 1
fi

echo -e "${GREEN}すべてのサービスが正常に起動しました！${NC}"
echo "以下のエンドポイントにアクセスできます："
echo "- Kong Admin API: http://localhost:8001"
echo "- Kong Proxy: http://localhost:8000"
echo "- Orion Context Broker: http://localhost:1026"