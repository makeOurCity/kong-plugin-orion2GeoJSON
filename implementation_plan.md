# FIWARE Orion から GeoJSON 形式への変換プラグイン実装計画

## 概要
Issue #5に基づく、FIWARE OrionからのレスポンスをGeoJSON形式に変換するKongプラグインの実装計画です。

## 実装フェーズ

### Phase 1: テスト環境構築
1. Orion環境の構築
   - 公式Orionイメージの導入 (.pongo/pongorc)
   - Docker Compose設定の作成（.pongo/orion.yml）
   - MongoDB設定の作成（.pongo/mongo.yml）
2. テスト環境のセットアップ
   - Pongoフレームワークの設定
   - 依存サービスの設定（Orion、MongoDB）
   - PostgreSQLは標準で利用可能
3. テストデータの準備
   - 位置情報を含むエンティティデータ
   - エラーケースのテストデータ
4. CI/CD環境の構成
   - GitHubアクションの設定
   - テスト自動化の実装

### Phase 2: プラグイン基本実装
1. スキーマ定義の更新
   ```lua
   fields = {
     entity_type = { type = "string", required = true },
     location_attr = { type = "string", required = true },
     output_format = { 
       type = "string", 
       required = true,
       default = "FeatureCollection",
       one_of = { "FeatureCollection", "Feature" }
     }
   }
   ```
2. ハンドラーの実装
   - body_filterフェーズでの変換処理
   - レスポンスヘッダーの更新
3. 基本的なエラーハンドリング
   - 設定エラーの処理
   - リクエストバリデーション

### Phase 3: 変換機能の実装
1. GeoJSON変換ロジックの実装
   - Orionエンティティ→GeoJSON Feature変換
   - 位置情報の正規化
   - 属性のマッピング処理
2. エラーハンドリング
   - 無効な入力データの処理
   - エラーレスポンスの生成
   - エラーログの実装
3. パフォーマンス最適化
   - メモリ使用量の最適化
   - 変換処理の効率化
   - キャッシュ戦略の実装

## テスト計画

### 単体テスト（Pongo使用）
1. スキーマバリデーション
   - 必須パラメータの検証
   - 無効な設定値のテスト
2. 変換ロジック
   - 基本的な変換テスト
   - エッジケースの処理
3. エラーハンドリング
   - 各種エラーケースの検証
   - エラーレスポンスの確認

### 統合テスト（実Orionを使用）
1. Orionとの連携
   - エンティティ取得と変換
   - 複数エンティティの処理
2. エンドツーエンドフロー
   - 完全なリクエスト/レスポンスサイクル
   - ヘッダー処理の確認
3. パフォーマンス
   - 大規模データセットでのテスト
   - メモリ使用量の測定
   - レスポンス時間の検証

## GitHubフロー
1. 各フェーズごとにfeatureブランチを作成
2. 実装完了後にプルリクエスト作成
3. レビュー後にマージ

## 注意事項
- PostgreSQLはKong Pongoに標準で含まれており、追加設定は不要
- 既存のKong認証メカニズムを使用（認証要件の変更なし）
- 各フェーズでのテスト実行と確認
- コードレビューの実施
- Orionバージョンの互換性確認
- パフォーマンス要件の遵守

## 開発環境要件
- Docker および Docker Compose
- Kong開発環境
- Pongo テストフレームワーク
- FIWARE Orion公式イメージ