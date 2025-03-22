# Kong Plugin: orion2GeoJSON

このKongプラグインは、FIWARE Orion Context Brokerからのレスポンスをインターセプトし、GeoJSON形式に変換するためのものです。

## プラグイン概要

FIWARE OrionのNGSI v2レスポンスをGeoJSON形式に変換するKongプラグインです。エンティティの位置情報を抽出し、標準的なGeoJSON形式で提供します。

## 技術アーキテクチャ

### プラグインの構成
```
kong/plugins/orion2GeoJSON/
├── handler.lua  # メイン処理ロジック
└── schema.lua   # 設定スキーマ定義
```

### 処理フロー
1. リクエスト受信
2. レスポンスボディの取得（body_filterフェーズ）
3. エンティティタイプと位置情報の検証
4. GeoJSON形式への変換
5. レスポンスの返却

## 設定パラメータ

| パラメータ | 必須 | デフォルト値 | 説明 |
|------------|------|--------------|------|
| entity_type | はい | - | 変換対象のエンティティタイプ（例：Room, Car など）。アルファベット、数字、ハイフン、アンダースコアのみ使用可能。 |
| location_attr | はい | - | 位置情報を含む属性名（例：location）。アルファベット、数字、ハイフン、アンダースコアのみ使用可能。 |
| output_format | はい | FeatureCollection | 出力形式。"FeatureCollection"（複数エンティティ）または"Feature"（単一エンティティ）。 |

## 使用例

### 1. 単一エンティティの変換

#### リクエスト
```bash
curl 'http://localhost:8000/orion/v2/entities/Room1?type=Room'
```

#### レスポンス（Feature形式）
```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [13.3986112, 52.554699]
  },
  "properties": {
    "temperature": 23,
    "humidity": 45
  }
}
```

### 2. 複数エンティティの変換

#### リクエスト
```bash
curl 'http://localhost:8000/orion/v2/entities?type=Room'
```

#### レスポンス（FeatureCollection形式）
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [13.3986112, 52.554699]
      },
      "properties": {
        "temperature": 23
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [13.3986113, 52.554700]
      },
      "properties": {
        "temperature": 25
      }
    }
  ]
}
```

## テスト環境のセットアップ

### 1. プロジェクトのセットアップ
```bash
# リポジトリのクローン
git clone https://github.com/[username]/kong-plugin-orion2GeoJSON.git
cd kong-plugin-orion2GeoJSON

# Pongoのインストール（初回のみ）
curl -Ls https://get.konghq.com/pongo | bash
export PATH=$PATH:~/.local/bin
```

## テストの実行

### 1. 自動テストの実行
```bash
# すべてのテストを実行
pongo run

# 特定のテストファイルを実行
pongo run spec/plugin-orionGeoJSON/01-unit_spec.lua
```

### 2. 手動テストの実行

#### テスト環境の起動
```bash
# テスト環境の起動
pongo up

# テスト用シェルの起動
pongo shell
```

#### プラグインのテスト
```bash
# Luaインタープリタの起動
luarocks test

# プラグインの動作確認
curl localhost:8000/orion/v2/entities
```

## 詳細ドキュメント

- [詳細な使用方法](docs/usage.md)
- [開発者向けドキュメント](docs/implementation.md)
- [テストガイド](docs/test.md)
- [テストケース仕様](docs/test_cases.md)

## 動作環境

- Kong Gateway
- Orion v3.10.1
- MongoDB 4.4

## ライセンス

Apache License 2.0
