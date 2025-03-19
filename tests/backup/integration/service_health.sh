#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 共通ユーティリティの読み込み
source "${SCRIPT_DIR}/utils.sh"

# Docker環境のチェック
if ! "${SCRIPT_DIR}/docker_check.sh"; then
    echo -e "${RED}Docker環境のチェックに失敗しました${NC}"
    exit 1
fi

# サービスの起動
echo "サービスの起動とヘルスチェックを開始します..."
if ! "${SCRIPT_DIR}/start_services.sh"; then
    echo -e "${RED}サービスの起動に失敗しました${NC}"
    cleanup 1
fi

# サービスの状態とKong設定の検証
if ! "${SCRIPT_DIR}/check_services.sh"; then
    echo -e "${RED}サービスとKong設定の検証に失敗しました${NC}"
    cleanup 1
fi

echo -e "${GREEN}すべてのチェックが正常に完了しました！${NC}"
exit 0