# 統合テストケース仕様

## 概要

統合テストでは、orion2GeoJSONプラグインのエンドツーエンド機能を検証します。Orion Context Brokerとの連携や、リクエスト・レスポンスの完全なサイクルを含みます。

## テスト環境のセットアップ

### 必要なサービス
1. Kong Gateway
2. Orion Context Broker
3. MongoDB

### 設定
```lua
-- テスト用プラグイン設定
local plugin_config = {
  entity_type = "Room",
  location_attr = "location",
  output_format = "FeatureCollection"
}
```

## テストカテゴリー

### 1. 単一エンティティの操作

#### 1.1 エンティティの取得と変換
```bash
# テストステップ：
# 1. テストエンティティの作成
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

# 2. 変換結果の取得と確認
curl 'http://localhost:8000/orion/v2/entities/TestRoom1?type=Room'

# 期待されるレスポンス：
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [13.3986112, 52.554699]
  },
  "properties": {
    "id": "TestRoom1",
    "temperature": 23
  }
}
```

#### 1.2 エラーケース
| テストケース | リクエスト | 期待されるレスポンス | ステータスコード |
|------------|-----------|-------------------|---------------|
| 存在しない | `GET /entities/NonExistent` | エラーレスポンス | 404 |
| タイプ不一致 | `GET /entities/Room1?type=Wrong` | エラーレスポンス | 404 |
| 無効なID | `GET /entities/Invalid@ID` | エラーレスポンス | 400 |

### 2. 複数エンティティの操作

#### 2.1 エンティティコレクションの取得
```bash
# テストステップ：
# 1. 複数のテストエンティティを作成
for i in {1..3}; do
  curl -X POST \
    'http://localhost:8000/orion/v2/entities' \
    -H 'Content-Type: application/json' \
    -d '{
      "id": "TestRoom'$i'",
      "type": "Room",
      "location": {
        "value": {
          "type": "Point",
          "coordinates": [13.3986112, 52.554699]
        },
        "type": "geo:json"
      }
    }'
done

# 2. 全エンティティの取得
curl 'http://localhost:8000/orion/v2/entities?type=Room'

# 期待されるレスポンス：
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {...},
      "properties": {...}
    },
    ...
  ]
}
```

#### 2.2 クエリパラメータ
| パラメータ | 例 | 説明 | 期待される結果 |
|-----------|-----|------|---------------|
| limit | `?limit=2` | 結果の制限 | 2件のフィーチャー |
| offset | `?offset=1` | 結果のスキップ | 最初の1件をスキップ |
| orderBy | `?orderBy=id` | 結果の並び替え | ID順にソート |

### 3. 特殊ケース

#### 3.1 位置情報属性のバリエーション
```json
// 異なる位置情報形式のテスト
{
  "location": {
    "value": {
      "type": "Point",
      "coordinates": [0, 0]
    }
  }
}

{
  "location": {
    "value": {
      "type": "Polygon",
      "coordinates": [[[0,0], [1,0], [1,1], [0,1], [0,0]]]
    }
  }
}
```

#### 3.2 プロパティタイプの処理
| プロパティタイプ | 例の値 | 期待される変換結果 |
|----------------|--------|------------------|
| Float | `{"value": 23.5}` | propertiesの数値 |
| Integer | `{"value": 23}` | propertiesの数値 |
| Boolean | `{"value": true}` | propertiesの真偽値 |
| Text | `{"value": "test"}` | propertiesの文字列 |
| Array | `{"value": [1,2,3]}` | propertiesの配列 |

### 4. レスポンスヘッダー

#### 4.1 ヘッダーの検証
| シナリオ | 期待されるヘッダー |
|---------|------------------|
| 成功時 | `Content-Type: application/geo+json` |
| エラー時 | `Content-Type: application/json` |

#### 4.2 ステータスコード
| シナリオ | 期待されるステータス |
|---------|------------------|
| 成功 | 200 |
| 未検出 | 404 |
| 無効なリクエスト | 400 |
| サーバーエラー | 500 |

## テスト実装

### テスト構造
```lua
describe("orion2GeoJSON統合テスト", function()
  local client

  setup(function()
    -- テスト環境のセットアップ
  end)

  before_each(function()
    -- テストデータの準備
  end)

  describe("単一エンティティ", function()
    -- 単一エンティティのテストケース
  end)

  describe("複数エンティティ", function()
    -- 複数エンティティのテストケース
  end)

  describe("エラーケース", function()
    -- エラーハンドリングのテストケース
  end)

  teardown(function()
    -- テスト環境のクリーンアップ
  end)
end)
```

## 統合テストの実行

### 前提条件
1. テスト環境の起動：
```bash
pongo up
```

### 実行方法
```bash
# 統合テストの実行
pongo run spec/plugin-orionGeoJSON/02-integration_spec.lua

# 詳細出力付きで実行
pongo run --verbose spec/plugin-orionGeoJSON/02-integration_spec.lua
```

### クリーンアップ
```bash
# テスト環境の停止
pongo down

# テストデータのクリーンアップ
curl -X DELETE 'http://localhost:8000/orion/v2/entities?type=Room'