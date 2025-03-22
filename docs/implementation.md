# orion2GeoJSON プラグイン技術仕様書

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

## 実装詳細

### スキーマ定義
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

### 変換ロジック

#### 1. エンティティの検証
- entity_typeによるフィルタリング
- location_attr属性の存在確認
- geo:json型の検証

#### 2. GeoJSON変換
- Feature形式：単一エンティティの変換
- FeatureCollection形式：複数エンティティの変換
- プロパティの抽出と設定

#### 3. エラーハンドリング
- 無効なエンティティタイプ → dummy Feature生成
- 位置情報属性なし → エラー情報付きFeature生成
- 無効な位置情報形式 → デフォルト座標での応答

## パフォーマンス最適化

### 実装済みの最適化
- ストリーミング処理による大規模データ対応
- メモリ使用量の最小化
- エラー時の早期リターン

### 計画中の最適化
- レスポンスキャッシング
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
- Kong開発環境
- Pongo テストフレームワーク

### バージョン要件
- Kong Gateway: 3.x以上
- Orion: v3.10.1
- MongoDB: 4.4

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