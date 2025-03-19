#!/bin/bash

# 共通ユーティリティの読み込み
source "$(dirname "$0")/utils.sh"

echo "Docker環境のチェックを開始します..."

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