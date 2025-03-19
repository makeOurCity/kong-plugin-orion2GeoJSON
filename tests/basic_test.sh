#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INTEGRATION_DIR="${SCRIPT_DIR}/integration"

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 統合テストの実行
echo "基本環境テストを開始します..."

# スクリプトの実行権限を確認・付与
chmod +x "${INTEGRATION_DIR}/docker_check.sh"
chmod +x "${INTEGRATION_DIR}/service_health.sh"

# Docker環境のチェック
echo "Docker環境をチェックしています..."
if ! "${INTEGRATION_DIR}/docker_check.sh"; then
    echo -e "${RED}Docker環境チェックに失敗しました${NC}"
    exit 1
fi

# サービスの起動と健康状態チェック
echo "サービスの起動と健康状態チェックを実行します..."
if ! "${INTEGRATION_DIR}/service_health.sh"; then
    echo -e "${RED}サービスの起動とヘルスチェックに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}すべてのテストが正常に完了しました！${NC}"
exit 0