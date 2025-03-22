# orion2GeoJSON プラグイン技術仕様書

## プラグイン概要

FIWARE OrionのNGSI v2レスポンスをGeoJSON形式に変換するKongプラグインです。エンティティの位置情報を抽出し、標準的なGeoJSON形式で提供します。

## 技術アーキテクチャ

### プラグインの構成
```
kong/plugins/orion2GeoJSON/
├── handler.lua  # メイン処理ロジック
├── schema.lua   # 設定スキーマ定義
└── tools.lua    # 共通ユーティリティ関数
```

### 処理フロー

1. リクエスト受信（Accessフェーズ）
   - クエリパラメータのチェック（format=geojson）
   - 変換フラグの設定

2. レスポンスヘッダー処理（Header Filterフェーズ）
   - Content-Typeの設定（application/geo+json）
   - Content-Lengthヘッダーの削除

3. レスポンスボディ処理（Body Filterフェーズ）
   - チャンク単位でのデータ受信
   - 完全なレスポンスボディの構築
   - JSONパースとバリデーション
   - GeoJSON形式への変換
   - 結果の出力

## 実装詳細

### スキーマ定義（schema.lua）

```lua
fields = {
  -- メインの設定項目
  entity_type = {
    type = "string",     -- エンティティタイプ
    required = true,     -- 必須パラメータ
    default = "Room"     -- デフォルト値
  },
  location_attr = {
    type = "string",     -- 位置情報属性名
    required = true,     -- 必須パラメータ
    default = "location" -- デフォルト値
  },
  output_format = {
    type = "string",     -- 出力形式指定
    required = true,     -- 必須パラメータ
    default = "FeatureCollection",
    one_of = {          -- 有効な値の制限
      "FeatureCollection",
      "Feature"
    }
  },
  conditional_transform = {
    type = "boolean",    -- 条件付き変換フラグ
    required = true,     -- 必須パラメータ
    default = false      -- デフォルト値
  }
}
```

### ハンドラー関数仕様（handler.lua）

#### 1. should_transform(conf)
- **目的**: 変換の必要性を判断
- **入力**: プラグイン設定
- **処理**:
  - conditional_transform設定の確認
  - クエリパラメータの解析
  - format=geojsonの検証
- **出力**: ブール値（変換要否）

#### 2. :access(conf)
- **目的**: リクエスト処理フェーズでの初期化
- **入力**: プラグイン設定
- **処理**:
  - 共有コンテキストの初期化
  - 変換フラグの設定

#### 3. :header_filter(conf)
- **目的**: レスポンスヘッダーの処理
- **入力**: プラグイン設定
- **処理**:
  - Content-Typeの設定
  - Content-Lengthの削除
  - レスポンスボディバッファの初期化

#### 4. :body_filter(conf)
- **目的**: レスポンスボディの変換
- **入力**: プラグイン設定
- **処理**:
  - チャンクデータの収集
  - JSONパース
  - GeoJSON変換
  - 結果の出力

### ユーティリティ関数仕様（tools.lua）

#### 1. generate_dummy_data(error_type, details)
- **目的**: エラー時のダミーデータ生成
- **入力**:
  - error_type: エラータイプ
  - details: エラー詳細
- **出力**: エラー情報を含むFeature

#### 2. generate_feature(entity, config)
- **目的**: エンティティからFeatureオブジェクトの生成
- **入力**:
  - entity: 変換対象エンティティ
  - config: プラグイン設定
- **処理**:
  - エンティティタイプの検証
  - 位置情報の抽出
  - プロパティの変換
- **出力**: GeoJSON Feature

#### 3. convert_single_entity(entity, config)
- **目的**: 単一エンティティの変換
- **入力**:
  - entity: 変換対象エンティティ
  - config: プラグイン設定
- **出力**: GeoJSON Feature

#### 4. convert_entity_array(entities, config)
- **目的**: 複数エンティティの変換
- **入力**:
  - entities: エンティティ配列
  - config: プラグイン設定
- **出力**: GeoJSON FeatureCollection

### エラーハンドリング

#### 1. パースエラー
- JSONパース失敗時のエラーFeature生成
- エラー詳細のログ記録
- 適切なエラーメッセージの返却

#### 2. バリデーションエラー
- エンティティタイプ不一致
- 位置情報属性の欠落
- 無効な位置情報形式

#### 3. 変換エラー
- 無効なデータ型
- 必須フィールドの欠落
- 配列処理エラー

## パフォーマンス最適化

### 実装済みの最適化
- チャンク単位でのストリーミング処理
- 早期リターンによる処理の最適化
- メモリ使用量の制御
- エラー時の適切なフォールバック

### 計画中の最適化
- レスポンスキャッシング機能
- バッチ処理の効率化
- クエリパラメータによるフィルタリング

## テスト方針

### 単体テスト
1. スキーマバリデーション
   - 必須パラメータの検証
   - パラメータ形式の検証
   - デフォルト値の確認

2. 変換ロジック
   - 単一エンティティの変換テスト
   - 複数エンティティの変換テスト
   - エラーケースの検証

### 統合テスト
1. Orion連携テスト
   - エンティティ作成と取得
   - 位置情報の変換確認
   - エラーハンドリングの確認

2. パフォーマンステスト
   - 大規模データセットでの動作確認
   - メモリ使用量の測定
   - レスポンス時間の計測

## 開発環境

### 必要な環境
- Docker および Docker Compose
- Kong開発環境（3.x以上）
- Pongo テストフレームワーク

### バージョン要件
- Kong Gateway: 3.x以上
- Orion: 3.10.1以上
- MongoDB: 4.4以上

## デプロイメント

### インストール手順
1. プラグインのビルド
2. Kongへの登録
3. 設定の適用

### 設定例
```yaml
plugins:
  - name: orion2GeoJSON
    config:
      entity_type: Room
      location_attr: location
      output_format: FeatureCollection
      conditional_transform: false
```

## 今後の開発計画

### 短期目標
- キャッシング機能の実装
- パフォーマンス最適化
- エラーログの強化

### 長期目標
- 複雑な位置情報タイプのサポート
- カスタム変換オプションの追加
- バッチ処理の最適化