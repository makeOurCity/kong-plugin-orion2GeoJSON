# Kong Gateway とOrion の連携検証機能の追加

## 作業ブランチ
```
feature/enhance-service-check
```

## 修正対象ファイル
1. tests/basic_test.sh
   - Docker環境チェックの追加
   - service_health.shの呼び出し統合

2. tests/integration/service_health.sh（新規作成）
   - Docker環境チェック
   - サービス起動検証
   - Kong Gateway設定検証
   - Orion API動作検証

3. tests/integration/check_services.sh
   - Kong Gateway設定の検証機能追加
   - Orion APIアクセス検証の追加

## 修正内容の詳細

### 1. tests/basic_test.sh の修正
```bash
#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INTEGRATION_DIR="${SCRIPT_DIR}/integration"

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "基本環境テストを開始します..."

# 統合テストの実行
if ! "${INTEGRATION_DIR}/service_health.sh"; then
    echo -e "${RED}サービス検証に失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}すべてのテストが正常に完了しました！${NC}"
exit 0
```

### 2. tests/integration/service_health.sh の作成
```bash
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
```

### 3. tests/integration/check_services.sh の拡張
```bash
# Kong Gatewayの設定を検証する関数を追加
verify_kong_configuration() {
    echo "Kong Gateway の設定を検証しています..."
    
    # サービス設定の検証
    local service_response=$(curl -s -i http://localhost:8001/services/orion)
    if ! echo "$service_response" | grep -q "200 OK"; then
        echo -e "${RED}エラー: Orionサービスが設定されていません${NC}"
        return 1
    fi

    # URLの確認
    if ! echo "$service_response" | grep -q "\"url\":\"http://orion:1026\""; then
        echo -e "${RED}エラー: サービスのURLが正しく設定されていません${NC}"
        return 1
    fi

    # ルート設定の検証
    local route_response=$(curl -s -i http://localhost:8001/services/orion/routes/orion-route)
    if ! echo "$route_response" | grep -q "200 OK"; then
        echo -e "${RED}エラー: Orionルートが設定されていません${NC}"
        return 1
    fi

    # パスの確認
    if ! echo "$route_response" | grep -q "\"/orion\""; then
        echo -e "${RED}エラー: ルートのパスが正しく設定されていません${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Kong Gateway の設定が正しく反映されています${NC}"
    return 0
}

verify_orion_routing() {
    echo "Orionルーティングの有効性を検証しています..."
    
    # バージョン情報の取得（基本的な疎通確認）
    local version_response=$(curl -s -i http://localhost:8000/orion/version)
    if ! echo "$version_response" | grep -q "200 OK"; then
        echo -e "${RED}エラー: Orion APIへのルーティングに失敗しました${NC}"
        echo "Response: $version_response"
        return 1
    fi
    
    # Orion v2 APIの動作確認
    local entities_response=$(curl -s -i http://localhost:8000/orion/v2/entities)
    if ! echo "$entities_response" | grep -q "200 OK"; then
        echo -e "${RED}エラー: Orion v2 APIへのルーティングに失敗しました${NC}"
        echo "Response: $entities_response"
        return 1
    fi

    # エンティティの作成テスト
    local create_response=$(curl -s -i -X POST http://localhost:8000/orion/v2/entities \
        -H "Content-Type: application/json" \
        -d '{"id": "test1", "type": "Test"}')
    if ! echo "$create_response" | grep -q "201 Created"; then
        echo -e "${RED}エラー: Orionエンティティの作成に失敗しました${NC}"
        echo "Response: $create_response"
        return 1
    fi

    # 作成したエンティティの取得確認
    local get_response=$(curl -s -i http://localhost:8000/orion/v2/entities/test1)
    if ! echo "$get_response" | grep -q "200 OK"; then
        echo -e "${RED}エラー: 作成したエンティティの取得に失敗しました${NC}"
        echo "Response: $get_response"
        return 1
    fi

    echo -e "${GREEN}✓ Orionルーティングが正常に機能しています${NC}"
    return 0
}

# メイン処理フローを拡張
echo "Kong Gateway とOrion の連携を検証しています..."

# Kong Gateway設定の検証
if ! verify_kong_configuration; then
    cleanup 1
fi

# Orion APIアクセスの検証
if ! verify_orion_access; then
    cleanup 1
fi

echo -e "${GREEN}Kong Gateway とOrion の連携が正常に機能しています！${NC}"
```

## テスト計画

1. コンテナ起動テスト
   - 全サービスの正常起動確認
   - PostgreSQLの準備完了確認
   - Kongのマイグレーション完了確認

2. Kong Gateway設定テスト
   - kong.ymlの設定が正しく反映されているか確認
   - サービス設定の検証
   - ルート設定の検証

3. OrionとKongの連携テスト
   - バージョン情報の取得
   - エンティティの作成
   - エラー時のレスポンス確認

## コミット計画
```
[新規追加] Enhance Kong and Orion integration tests

- Add service_health.sh for comprehensive health checks
- Enhance check_services.sh with detailed Kong configuration verification
- Add Orion API functionality tests through Kong Gateway
- Update basic_test.sh to use new health check script
- Improve error handling and reporting
```

## 注意事項
- kong.ymlの設定を基準とした検証を実装
- サービスとルートの登録はkong.ymlで管理
- Orion APIの基本機能を検証
- エラー発生時は詳細なメッセージを表示
- クリーンアップ処理は確実に実行

### 1. 新しい検証関数の追加
`tests/integration/check_services.sh`に以下の関数を追加：

```bash

# ルーティングの有効性を確認する関数
verify_kong_routing() {
    local response=$(curl -s -i http://localhost:8000/orion/version)
    
    # レスポンスの検証
    if [[ "$response" =~ "200 OK" ]]; then
        echo -e "${GREEN}✓ ルーティングが正常に機能しています${NC}"
        return 0
    else
        echo -e "${RED}エラー: ルーティングの検証に失敗しました${NC}"
        return 1
    fi
}

# レスポンスを検証する共通関数
check_response() {
    local response=$1
    local operation=$2
    
    if [[ "$response" =~ "201" ]]; then
        echo -e "${GREEN}✓ ${operation}が成功しました${NC}"
        return 0
    else
        echo -e "${RED}エラー: ${operation}に失敗しました${NC}"
        echo "$response"
        return 1
    fi
}
```

### 2. メイン処理フローの修正
既存のサービス確認処理の後に、以下の処理を追加：

```bash
# Kong Gateway の設定検証
echo "Kong Gateway の設定を検証しています..."

# ルーティングの有効性確認
if ! verify_kong_routing; then
    echo -e "${RED}Kong ルーティングの検証に失敗しました${NC}"
    cleanup 1
fi

echo -e "${GREEN}Kong Gateway の設定が正常に完了しました！${NC}"
```

### 3. エラーハンドリングの強化
- 各検証ステップでの詳細なエラーメッセージの表示
- 失敗時のクリーンアップ処理の確実な実行

### 4. テスト計画
1. コンテナの正常起動確認
2. サービス登録のテスト
3. ルーティング設定のテスト
4. エンドポイントアクセスのテスト

## コミット計画
```
[新規追加] Enhance service verification in check_services.sh

- Add Kong service registration verification
- Add route configuration verification
- Add routing functionality verification
- Improve error handling and cleanup
```

## 注意事項
- 既存の機能は保持
- エラー発生時は適切なメッセージを表示
- クリーンアップ処理は確実に実行