#!/bin/bash

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}クリーンアップを開始します...${NC}"

# 終了処理を行う関数
cleanup() {
    local exit_code=$1
    local show_message=${2:-true}

    # Docker Composeが利用可能か確認
    if command -v docker compose &> /dev/null; then
        echo "Docker Composeのサービスを停止しています..."
        docker compose down --volumes --remove-orphans 2>/dev/null || true
    fi

    # 未使用のネットワークとボリュームの削除
    echo "未使用のDockerリソースを削除しています..."
    docker network prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true

    if [ "$show_message" = true ]; then
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}クリーンアップが正常に完了しました${NC}"
        else
            echo -e "${RED}クリーンアップ中にエラーが発生しました（終了コード: $exit_code）${NC}"
        fi
    fi

    exit $exit_code
}

# SIGINTシグナル（Ctrl+C）のハンドリング
trap 'echo -e "\n${YELLOW}中断シグナルを受信しました。クリーンアップを実行します...${NC}" && cleanup 130 false' INT

# メイン処理
cleanup 0