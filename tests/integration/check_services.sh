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

# サービスの状態確認
echo "サービスの状態を確認しています..."
sleep 5  # サービスの起動を待つ

# PostgreSQLの起動を待つ
echo "PostgreSQLの準備を待っています..."
for i in {1..30}; do
    if docker compose exec kong-database pg_isready -U kong > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQLが準備完了しました${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}エラー: PostgreSQLの準備が完了しませんでした${NC}"
        cleanup 1
    fi
    echo "PostgreSQLの準備を待っています... ($i/30)"
    sleep 1
done

# 各サービスの確認
services=("kong-database" "kong" "orion" "mongo")
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

echo -e "${GREEN}すべてのサービスが正常に起動しています！${NC}"
echo "以下のエンドポイントにアクセスできます："
echo "- Kong Admin API: http://localhost:8001"
echo "- Kong Proxy: http://localhost:8000"
echo "- Orion Context Broker: http://localhost:1026"