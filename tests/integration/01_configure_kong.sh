#!/bin/bash

# 共通ユーティリティの読み込み
source "$(dirname "$0")/utils.sh"

# Kongの設定を行う関数
configure_kong_service() {
    echo "Kongサービスの設定を開始します..."
    
    # Orionサービスの登録
    local service_response=$(curl -s -i -X POST http://localhost:8001/services \
        --data name=orion \
        --data url=http://orion:1026)
    
    if ! echo "$service_response" | grep -q "201 Created"; then
        echo -e "${RED}エラー: Orionサービスの登録に失敗しました${NC}"
        echo "Response: $service_response"
        return 1
    fi
    
    echo -e "${GREEN}✓ Orionサービスが正常に登録されました${NC}"
    
    # Orionルートの登録
    local route_response=$(curl -s -i -X POST http://localhost:8001/services/orion/routes \
        --data name=orion-route \
        --data 'paths[]=/orion')
    
    if ! echo "$route_response" | grep -q "201 Created"; then
        echo -e "${RED}エラー: Orionルートの登録に失敗しました${NC}"
        echo "Response: $route_response"
        return 1
    fi
    
    echo -e "${GREEN}✓ Orionルートが正常に登録されました${NC}"
    return 0
}

# メイン処理
echo "Kongの設定を開始します..."

# Kongの設定
if ! configure_kong_service; then
    cleanup 1
fi

echo -e "${GREEN}Kongの設定が正常に完了しました！${NC}"