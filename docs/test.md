# orion2GeoJSON プラグインテストマニュアル

## テスト環境のセットアップ

### 1. 必要なツールのインストール
```bash
# Pongoのインストール
curl -Ls https://get.konghq.com/pongo | bash
export PATH=$PATH:~/.local/bin

# プロジェクトの初期化
cd kong-plugin-orion2GeoJSON
pongo init
```

### 2. 環境変数の設定
```bash
# Pongoの依存サービスを設定
cat > .pongo/pongorc << EOF
--postgres
--orion
--mongo
EOF
```

## テストの実行

### 1. ユニットテストの実行
```bash
# すべてのテストを実行
pongo run

# 特定のテストファイルを実行
pongo run spec/plugin-orionGeoJSON/01-unit_spec.lua
```

### 2. 統合テストの実行

#### Orionサービスの準備
1. テスト環境の起動：
```bash
pongo up
```

2. テストデータの作成：
```bash
# テストエンティティの作成
curl -X POST \
  'http://localhost:8000/orion/v2/entities' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": "TestRoom1",
    "type": "Room",
    "temperature": {
      "value": 23,
      "type": "Float"
    },
    "location": {
      "value": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "type": "geo:json"
    }
  }'
```

#### テストケースの実行
1. 単一エンティティの変換テスト：
```bash
curl 'http://localhost:8000/orion/v2/entities/TestRoom1?type=Room'
```

2. 複数エンティティの変換テスト：
```bash
curl 'http://localhost:8000/orion/v2/entities?type=Room'
```

## テスト項目チェックリスト

### 1. スキーマバリデーション
- [ ] entity_typeの必須チェック
- [ ] location_attrの必須チェック
- [ ] output_formatの値チェック
- [ ] 無効なパラメータ値のエラー処理

### 2. 変換機能
- [ ] 単一エンティティの正常変換
- [ ] 複数エンティティの正常変換
- [ ] 位置情報属性の正確な抽出
- [ ] プロパティの適切な変換

### 3. エラーケース
- [ ] 存在しないエンティティタイプ
- [ ] 不正な位置情報形式
- [ ] 位置情報属性の欠落
- [ ] JSONパースエラー

### 4. レスポンスヘッダー
- [ ] Content-Typeの設定
- [ ] エラー時のステータスコード

## パフォーマンステスト

### 1. 負荷テスト
```bash
# 100件のエンティティでのテスト
for i in {1..100}; do
  curl -X POST \
    'http://localhost:8000/orion/v2/entities' \
    -H 'Content-Type: application/json' \
    -d "{
      \"id\": \"TestRoom$i\",
      \"type\": \"Room\",
      \"location\": {
        \"value\": {
          \"type\": \"Point\",
          \"coordinates\": [13.3986112, 52.554699]
        },
        \"type\": \"geo:json\"
      }
    }"
done
```

### 2. メモリ使用量の確認
```bash
# Kongプロセスのメモリ使用量を確認
ps aux | grep kong
```

## トラブルシューティング

### よくある問題と解決方法

1. テスト環境が起動しない場合
```bash
# コンテナの状態確認
docker ps -a

# ログの確認
docker logs kong-test
```

2. テストが失敗する場合
```bash
# テストログの詳細表示
pongo run --verbose

# 特定のテストの詳細実行
pongo run --verbose spec/plugin-orionGeoJSON/01-unit_spec.lua
```

### テスト環境のクリーンアップ
```bash
# テスト環境の停止
pongo down

# すべてのコンテナとボリュームの削除
pongo nuke