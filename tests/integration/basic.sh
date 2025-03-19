#!/bin/bash

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# スクリプトの場所を取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CLEANUP_SCRIPT="${SCRIPT_DIR}/cleanup.sh"

# 終了時の処理
cleanup() {
    local exit_code=$1
    if [ -x "$CLEANUP_SCRIPT" ]; then
        "$CLEANUP_SCRIPT"
    else
        chmod +x "$CLEANUP_SCRIPT" && "$CLEANUP_SCRIPT"
    fi
    exit $exit_code
}

# SIGINTシグナル（Ctrl+C）のハンドリング
trap 'echo "中断されました" && cleanup 130' INT

echo "基本環境テストを開始します..."

# Dockerコマンドの確認
if ! command -v docker &> /dev/null; then
    echo -e "${RED}エラー: Dockerがインストールされていません。${NC}"
    echo "以下のURLからDockerをインストールしてください："
    echo "https://docs.docker.com/get-docker/"
    cleanup 1
fi

echo -e "${GREEN}✓ Dockerが正しくインストールされています${NC}"

# Docker Composeコマンドの確認
if ! docker compose version &> /dev/null; then
    echo -e "${RED}エラー: Docker Composeが利用できません。${NC}"
    echo "Docker Desktop最新版をインストールしてください。"
    cleanup 1
fi

echo -e "${GREEN}✓ Docker Composeが利用可能です${NC}"

# サービスの起動
echo "サービスを起動しています..."
if ! docker compose up -d; then
    echo -e "${RED}エラー: サービスの起動に失敗しました${NC}"
    cleanup 1
fi

# 各サービスの状態確認
echo "サービスの状態を確認しています..."
sleep 5  # サービスの起動を待つ

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

echo -e "${GREEN}すべてのテストが成功しました！${NC}"
echo "以下のエンドポイントにアクセスできます："
echo "- Kong Admin API: http://localhost:8001"
echo "- Kong Proxy: http://localhost:8000"
echo "- Orion Context Broker: http://localhost:1026"

# 正常終了時のクリーンアップ
cleanup 0