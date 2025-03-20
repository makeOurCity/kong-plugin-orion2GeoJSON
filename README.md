# Kong Plugin: orion2GeoJSON

このKongプラグインは、FIWARE Orion Context Brokerからのレスポンスをインターセプトし、GeoJSON形式に変換するためのものです。

## ファイル構造

```
.
├── .pongo/
│   ├── pongorc        # Pongo依存サービス定義
│   ├── orion.yml      # Orionコンテナ設定
│   └── mongo.yml      # MongoDBコンテナ設定
├── kong/
│   └── plugins/
│       └── plugin-orionGeoJSON/
│           ├── handler.lua          # プラグインのメインロジック
│           └── schema.lua           # プラグイン設定のスキーマ定義
├── spec/
│   └── plugin-orionGeoJSON/
│       └── 01-unit_spec.lua        # ユニットテスト
└── plugin-orion2GeoJSON-0.1.0-1.rockspec  # パッケージング設定

~/.kong-pongo/                       # Pongoのグローバル設定ディレクトリ
├── kong-versions/                   # 各バージョンのKongイメージ
├── kong-ee-versions/               # エンタープライズ版Kongイメージ（必要な場合）
└── images/                         # その他の依存イメージ
```

## 開発環境のセットアップ

1. Pongoのインストール:
```bash
curl -Ls https://get.konghq.com/pongo | bash
```

2. 環境変数のセットアップ:
```bash
export PATH=$PATH:~/.local/bin
```

3. プロジェクトの初期化:
```bash
# 開発用のプラグインディレクトリに移動
cd kong-plugin-orion2GeoJSON

# Pongoの開発環境を初期化
pongo init

# 必要なファイルを作成
mkdir -p .pongo
```

4. Pongo設定ファイルの作成:

a. .pongrcファイル:
```bash
--postgres  # PostgreSQLは標準で含まれています
--orion
--mongo
```

b. .pongo/orion.yml:
```yaml
services:
  orion:
    image: fiware/orion:3.10.1
    depends_on:
      mongo:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:1026/version"]
      interval: 5s
      retries: 5
    networks:
      - ${NETWORK_NAME}
```

c. .pongo/mongo.yml:
```yaml
services:
  mongo:
    image: mongo:4.4
    command: mongod --nojournal
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - ${NETWORK_NAME}
```

5. 開発環境の起動:
```bash
# テスト環境のコンテナを起動
pongo up
```

## テストデータの作成

以下は、テストで使用する位置情報を含むエンティティの例です：

```bash
# エンティティの作成
curl -X POST \
  'http://localhost:8000/orion/v2/entities' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": "Room1",
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

## 開発とテスト

Pongoを使用してテストを実行:

```bash
# すべてのテストを実行
pongo run

# 特定のテストの実行
pongo run spec/plugin-orionGeoJSON/01-unit_spec.lua

# テスト環境のシェルにアクセス
pongo shell

# テスト環境のクリーンアップ
pongo down
```

## プラグインの設定

Kongの設定ファイル（`kong.conf`）にプラグインを追加:
```bash
plugins = bundled,plugin-orionGeoJSON
```

プラグインの基本的な設定例：

```yaml
plugins:
  - name: plugin-orionGeoJSON
    config:
      example_field: "custom value"
```

## プロダクション環境へのデプロイ

1. プラグインをインストール:
```bash
luarocks make
```

2. Kongを再起動:
```bash
kong restart
```

## 注意点

- PostgreSQLはKong Pongoに標準で含まれており、追加設定は不要です
- Orion v3.10.1とMongoDB 4.4を使用しています
- Orionはmongoサービスの正常起動を待って起動します
- すべてのサービスは同じPongoネットワーク上で動作します
- テスト環境では認証は無効化されています

## ライセンス

Apache License 2.0