# Phase 1: Pongo環境でのFiware Orion構築

## 環境構成
1. Pongo開発環境
   - Kong Plugin開発環境（PostgreSQL標準搭載）
   - Orion v3.10.1
   - MongoDB 4.4

## ディレクトリ構造と設定ファイル
```
.
├── .pongo/
│   ├── pongorc        # 依存サービス定義
│   │   --orion        # Fiware Orion
│   │   --mongo        # MongoDB
│   ├── orion.yml      # Orionコンテナ設定
│   └── mongo.yml      # MongoDBコンテナ設定
└── [その他のプラグインファイル]
```

## 実装手順

1. Pongo設定ファイルの作成

   a. .pongo/pongorc（依存サービスの定義）
   ```
   --orion
   --mongo
   ```

   b. .pongo/orion.yml
   ```yaml
   version: '3.5'
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

   c. .pongo/mongo.yml
   ```yaml
   version: '3.5'
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

2. 開発環境のセットアップ
   ```bash
   # Pongo環境の初期化
   pongo init

   # テスト環境の起動
   pongo up
   ```

3. 動作確認用テストデータ
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

## テスト計画
1. 環境起動確認
   - Pongo環境の初期化確認
   - 各コンポーネントのヘルスチェック
   - ネットワーク接続確認

2. Orion API動作確認
   - エンティティの作成/取得/更新/削除
   - 位置情報を含むクエリ
   - バッチ操作

3. プラグイン開発環境との連携確認
   - Kongプラグインのテスト実行
   - Orionへのリクエスト/レスポンス確認
   - エラーケースのハンドリング

## 成功基準
1. Pongo環境で全コンポーネントが正常に起動すること
2. Orionの基本機能が正常に動作すること
3. プラグイン開発環境からOrionにアクセスできること
4. テストデータのCRUD操作が正常に行えること

## 注意点
- PostgreSQLはPongoに標準搭載されている
- Orionはmongoサービスの正常起動を待って起動する
- MongoDBのヘルスチェックを適切に設定する
- サービス名は.pongo/pongorcで指定した名前と一致させる
- 全てのサービスを同じネットワーク上で起動する

## 次のステップ
1. .pongo/pongorcの設定確認
2. .pongo/ディレクトリ内のYAMLファイルの確認
3. 開発環境の初期化と動作確認
4. テストデータを使用した基本機能の検証