# プラグインスキーマ設計

## 基本情報
- プラグイン名: plugin-orionGeoJSON
- 説明: FIWARE OrionのレスポンスをGeoJSON形式に変換するKongプラグイン

## スキーマ構造

### 基本フィールド
```lua
{ consumer = typedefs.no_consumer }  -- コンシューマーに依存しない
{ protocols = typedefs.protocols_http }  -- HTTPプロトコルのみサポート
```

### 設定フィールド
1. entity_type
   - 型: string
   - 必須: true
   - 説明: 変換対象のFIWARE Orionエンティティタイプ
   - バリデーション: 空文字列不可

2. location_attr
   - 型: string
   - 必須: true
   - 説明: 位置情報を含む属性名
   - バリデーション: 空文字列不可

3. output_format
   - 型: string
   - 必須: true
   - デフォルト値: "FeatureCollection"
   - 有効値: ["FeatureCollection", "Feature"]
   - 説明: 出力するGeoJSONのフォーマット

## バリデーションルール

### カスタムバリデーション
1. location_attr検証
   - 不正な文字が含まれていないか確認
   - 予約語との重複チェック

2. entity_type検証
   - 不正な文字が含まれていないか確認
   - Orionの命名規則に準拠しているか確認

## エラーメッセージ
- フィールドの必須エラー
  - "The [field_name] is required"
- 無効な値エラー
  - "Invalid [field_name]: [reason]"
- フォーマットエラー
  - "Invalid output_format. Must be one of: FeatureCollection, Feature"

## 実装例
```lua
local typedefs = require "kong.db.schema.typedefs"

return {
  name = "plugin-orionGeoJSON",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { entity_type = {
              type = "string",
              required = true,
              match = "^[a-zA-Z0-9_-]+$"
            }
          },
          { location_attr = {
              type = "string",
              required = true,
              match = "^[a-zA-Z0-9_-]+$"
            }
          },
          { output_format = {
              type = "string",
              required = true,
              default = "FeatureCollection",
              one_of = { "FeatureCollection", "Feature" }
            }
          }
        }
      }
    }
  }
}
```

## 注意事項
1. スキーマ定義はKong Gateway 3.x系の仕様に準拠
2. すべてのフィールドは適切なバリデーションを実装
3. エラーメッセージは明確で分かりやすい内容に
4. 将来の拡張性を考慮した設計

## 今後の拡張検討項目
1. 追加の設定オプション
   - エラーハンドリングの設定
   - デバッグモードの設定
   - キャッシュ設定

2. パフォーマンス設定
   - バッファサイズの設定
   - タイムアウト設定