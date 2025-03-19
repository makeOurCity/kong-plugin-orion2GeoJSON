#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INTEGRATION_DIR="${SCRIPT_DIR}/integration"

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "基本環境テストを開始します..."

# スクリプトの実行権限を付与
echo "スクリプトの実行権限を確認しています..."
chmod +x "${INTEGRATION_DIR}/docker_check.sh"
chmod +x "${INTEGRATION_DIR}/start_services.sh"
chmod +x "${INTEGRATION_DIR}/check_services.sh"
chmod +x "${INTEGRATION_DIR}/service_health.sh"
chmod +x "${INTEGRATION_DIR}/cleanup.sh"

# 統合テストの実行
echo "サービスの検証を開始します..."
if ! "${INTEGRATION_DIR}/service_health.sh"; then
    echo -e "${RED}サービス検証に失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}すべてのテストが正常に完了しました！${NC}"
echo "Kong GatewayとOrion Context Brokerが正常に連携しています"
exit 0