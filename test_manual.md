# Fiware Orion環境テスト手順

## 環境セットアップ手順

1. 依存サービスの確認
   ```bash
   cat .pongo/pongorc
   ```
   以下の3つのサービスが定義されていることを確認：
   - orion
   - mongo

2. 環境の初期化と起動
   ```bash
   # 初期化
   pongo init

   # 環境起動
   pongo up
   ```

## 動作確認手順

1. Orionサービスの稼働確認
   ```bash
   curl http://localhost:8000/orion/version
   ```

2. テストデータの登録
   ```bash
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

3. データ取得確認
   ```bash
   curl http://localhost:8000/orion/v2/entities/Room1
   ```

## エラー発生時の対応

1. サービス状態の確認
   ```bash
   pongo status
   ```

2. ログの確認
   ```bash
   pongo logs
   ```

3. 環境の再起動
   ```bash
   pongo down
   pongo up