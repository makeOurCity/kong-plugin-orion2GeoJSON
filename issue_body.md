# Kong Gateway とOrion の連携検証機能の強化

## 概要
現在のcheck_services.shスクリプトは、コンテナの起動状態のみを確認しています。Kong GatewayとOrion Context Brokerの連携を確実にするため、以下の検証機能を追加する必要があります。

## 追加する機能
1. Kong Gateway 設定の検証
   - kong.ymlで定義されたサービス設定の反映確認
   - kong.ymlで定義されたルート設定の反映確認
   - 設定の有効性確認

2. Orion APIの動作検証
   - バージョン情報の取得テスト
   - エンティティの作成テスト
   - エラー時のレスポンス確認

3. エンドポイントの統合テスト
   - Kong Proxyを介したOrionへのアクセス確認
   - 適切なルーティングの検証
   - レスポンス内容の検証

## 変更するファイル
- tests/basic_test.sh
- tests/integration/service_health.sh（新規作成）
- tests/integration/check_services.sh

## テスト計画
1. Kong Gateway設定の検証
   - kong.ymlの設定が正しく反映されているか確認
   - Admin APIを使用した設定の検証

2. Orion APIの機能テスト
   - 基本的なCRUD操作の確認
   - エラーケースの動作確認

3. 統合テスト
   - Kong Gateway経由のOrionアクセス
   - 全体的な連携の確認

## 注意事項
- kong.ymlの設定を基準とした検証を実装
- テスト失敗時は適切なエラーメッセージを表示
- 既存のコンテナ状態確認機能は維持
- クリーンアップ処理の確実な実行