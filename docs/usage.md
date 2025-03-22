# orion2GeoJSON プラグイン使用ガイド

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

## エラーケース

### 1. 無効なエンティティタイプ

指定されたentity_typeが見つからない場合：

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [0, 0]
  },
  "properties": {
    "error": "invalid_entity_type",
    "details": "Expected type 'Room', got 'Sensor'",
    "original_data": { ... }
  }
}
```

### 2. 位置情報属性が見つからない

location_attrで指定された属性が見つからない場合：

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [0, 0]
  },
  "properties": {
    "error": "location_attr_not_found",
    "details": "Attribute 'location' not found",
    "original_data": { ... }
  }
}
```

### 3. 無効な位置情報フォーマット

位置情報が正しいGeoJSON形式でない場合：

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [0, 0]
  },
  "properties": {
    "error": "invalid_location_format",
    "details": "Invalid format for location attribute 'location'",
    "original_data": { ... }
  }
}
```

## 注意事項

1. 位置情報属性は必ずgeo:json型である必要があります
2. エラー時も常に有効なGeoJSONが返されます
3. エラーの場合、座標は[0, 0]にデフォルト設定されます
4. propertiesには位置情報属性以外のすべての属性値が含まれます