# ユニットテストケース仕様

## 概要

ユニットテストは、orion2GeoJSONプラグインの個々のコンポーネントを単独でテストします。スキーマのバリデーション、データ変換、エラー処理などの基本機能を検証します。

## テストカテゴリー

### 1. スキーマバリデーションテスト

#### 1.1 必須パラメータ
| テストケース | 入力 | 期待結果 | 説明 |
|------------|------|----------|------|
| entity_type未指定 | `{ location_attr = "location" }` | 無効 | entity_typeが必須であることを確認 |
| location_attr未指定 | `{ entity_type = "Room" }` | 無効 | location_attrが必須であることを確認 |
| 全パラメータ指定 | `{ entity_type = "Room", location_attr = "location" }` | 有効 | 最小限の有効な設定を確認 |

#### 1.2 パラメータ形式の検証
| テストケース | 入力 | 期待結果 | 説明 |
|------------|------|----------|------|
| 無効なentity_type | `{ entity_type = "Room@Invalid" }` | 無効 | entity_typeの形式チェック |
| 無効なlocation_attr | `{ location_attr = "location@Invalid" }` | 無効 | location_attrの形式チェック |
| 無効なoutput_format | `{ output_format = "Invalid" }` | 無効 | output_formatの値チェック |

### 2. データ変換テスト

#### 2.1 単一エンティティ変換
```lua
-- テストケース：基本的なエンティティ変換
local entity = {
  id = "Room1",
  type = "Room",
  temperature = { value = 23, type = "Float" },
  location = {
    value = {
      type = "Point",
      coordinates = {13.3986112, 52.554699}
    },
    type = "geo:json"
  }
}

-- 期待される結果の構造
{
  type = "Feature",
  geometry = {
    type = "Point",
    coordinates = {13.3986112, 52.554699}
  },
  properties = {
    id = "Room1",
    temperature = 23
  }
}
```

#### 2.2 プロパティ変換テスト
| テストケース | 入力プロパティ | 期待される出力 | 説明 |
|------------|--------------|--------------|------|
| 数値 | `{ value = 23, type = "Float" }` | `23` | 数値プロパティの変換 |
| テキスト | `{ value = "test", type = "Text" }` | `"test"` | テキストプロパティの変換 |
| 真偽値 | `{ value = true, type = "Boolean" }` | `true` | 真偽値プロパティの変換 |

### 3. エラーハンドリングテスト

#### 3.1 エンティティタイプの検証
```lua
-- テストケース：無効なエンティティタイプ
local entity = {
  id = "Sensor1",
  type = "Sensor",  -- 設定されたタイプと異なる
  location = {...}
}

-- 期待されるエラー
{
  error = "invalid_entity_type",
  message = "エンティティタイプが一致しません"
}
```

#### 3.2 位置情報属性テスト
```lua
-- テストケース：位置情報属性の欠落
local entity = {
  id = "Room1",
  type = "Room"
  -- location属性が欠落
}

-- 期待されるエラー
{
  error = "location_attr_not_found",
  message = "位置情報属性が見つかりません"
}
```

#### 3.3 無効な位置情報形式
```lua
-- テストケース：無効な位置情報形式
local entity = {
  id = "Room1",
  type = "Room",
  location = {
    value = "invalid",
    type = "geo:json"
  }
}

-- 期待されるエラー
{
  error = "invalid_location_format",
  message = "位置情報の形式が無効です"
}
```

## 実装の詳細

### テストファイルの構造
```lua
describe("orion2GeoJSONプラグイン", function()
  describe("スキーマバリデーション", function()
    -- 必須パラメータのテスト
    -- パラメータ形式のテスト
  end)

  describe("エンティティ変換", function()
    -- 単一エンティティ変換テスト
    -- プロパティ変換テスト
  end)

  describe("エラーハンドリング", function()
    -- エンティティタイプ検証テスト
    -- 位置情報属性テスト
    -- 形式検証テスト
  end)
end)
```

### テストヘルパー関数
```lua
-- スキーマバリデーション用ヘルパー関数
local function validate_config(config)
  local ok, err = validate(config)
  return ok, err
end

-- エンティティ変換用ヘルパー関数
local function convert_and_verify(entity, expected)
  local result = convert_single_entity(entity, config)
  assert.same(expected, result)
end
```

## テストカバレッジ要件

- スキーマバリデーション: 100%カバレッジ
- データ変換関数: 100%カバレッジ
- エラーハンドリングパス: 100%カバレッジ
- ヘルパー関数: 100%カバレッジ

## ユニットテストの実行方法

```bash
# 全ユニットテストの実行
pongo run spec/plugin-orionGeoJSON/01-unit_spec.lua

# カバレッジ付きで実行
pongo run --coverage spec/plugin-orionGeoJSON/01-unit_spec.lua