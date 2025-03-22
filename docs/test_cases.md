# orion2GeoJSON プラグインテストケース仕様

## スキーマテスト

### 必須パラメータのバリデーション
1. entity_typeのみ指定
   ```lua
   ok, err = validate({ entity_type = "Room" })
   assert.is_falsy(ok)
   ```

2. location_attrのみ指定
   ```lua
   ok, err = validate({ location_attr = "location" })
   assert.is_falsy(ok)
   ```

3. 全パラメータ指定（正常系）
   ```lua
   ok, err = validate({
     entity_type = "Room",
     location_attr = "location",
     output_format = "FeatureCollection"
   })
   assert.is_truthy(ok)
   ```

### パラメータ形式のバリデーション
1. entity_type形式チェック
   ```lua
   ok, err = validate({
     entity_type = "Room@Invalid",
     location_attr = "location",
     output_format = "FeatureCollection"
   })
   assert.is_falsy(ok)
   ```

2. location_attr形式チェック
   ```lua
   ok, err = validate({
     entity_type = "Room",
     location_attr = "location@Invalid",
     output_format = "FeatureCollection"
   })
   assert.is_falsy(ok)
   ```

3. output_format値チェック
   ```lua
   ok, err = validate({
     entity_type = "Room",
     location_attr = "location",
     output_format = "Invalid"
   })
   assert.is_falsy(ok)
   ```

## 変換機能テスト

### 単一エンティティ変換
1. 基本的な変換
   ```lua
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
   local result = convert_single_entity(entity, config)
   assert.equals("Feature", result.type)
   assert.same({13.3986112, 52.554699}, result.geometry.coordinates)
   ```

2. 追加プロパティの変換
   ```lua
   -- temperatureとhumidityを含むエンティティ
   local result = convert_single_entity(entity, config)
   assert.equals(23, result.properties.temperature)
   assert.equals(45, result.properties.humidity)
   ```

### 複数エンティティ変換
1. FeatureCollection形式
   ```lua
   local entities = {entity1, entity2}
   local result = convert_entity_array(entities, config)
   assert.equals("FeatureCollection", result.type)
   assert.equals(2, #result.features)
   ```

2. Feature形式（最初のエンティティのみ）
   ```lua
   config.output_format = "Feature"
   local result = convert_entity_array(entities, config)
   assert.equals("Feature", result.type)
   ```

## エラーケーステスト

### エンティティタイプエラー
1. 不一致のエンティティタイプ
   ```lua
   local entity = { type = "Sensor" }
   local result = convert_single_entity(entity, config)
   assert.equals("invalid_entity_type", result.properties.error)
   ```

### 位置情報エラー
1. 位置情報属性なし
   ```lua
   local entity = { type = "Room" }
   local result = convert_single_entity(entity, config)
   assert.equals("location_attr_not_found", result.properties.error)
   ```

2. 無効な位置情報形式
   ```lua
   local entity = {
     type = "Room",
     location = { value = "invalid" }
   }
   local result = convert_single_entity(entity, config)
   assert.equals("invalid_location_format", result.properties.error)
   ```

## 統合テスト

### Orionエンティティの取得と変換
1. 単一エンティティのエンドツーエンドテスト
   ```bash
   # エンティティの作成
   curl -X POST 'http://localhost:8000/orion/v2/entities' -d '{...}'
   
   # 変換結果の確認
   curl 'http://localhost:8000/orion/v2/entities/Room1?type=Room'
   ```

2. 複数エンティティの取得
   ```bash
   # 複数エンティティの作成
   for i in {1..3}; do
     curl -X POST 'http://localhost:8000/orion/v2/entities' -d '{...}'
   done
   
   # 変換結果の確認
   curl 'http://localhost:8000/orion/v2/entities?type=Room'
   ```

### エラー応答の確認
1. 存在しないエンティティ
   ```bash
   curl 'http://localhost:8000/orion/v2/entities/NonExistent?type=Room'
   ```

2. 無効なクエリ
   ```bash
   curl 'http://localhost:8000/orion/v2/entities?type=InvalidType'
   ```

## パフォーマンステスト

### 大規模データセット
1. 100エンティティの同時変換
   ```lua
   local entities = generate_test_entities(100)
   local start_time = ngx.now()
   local result = convert_entity_array(entities, config)
   local duration = ngx.now() - start_time
   assert.is_true(duration < 0.1) -- 100ms以内
   ```

2. メモリ使用量の検証
   ```lua
   local before_mem = collectgarbage("count")
   local result = convert_entity_array(large_entities, config)
   local after_mem = collectgarbage("count")
   assert.is_true((after_mem - before_mem) < 1024) -- 1MB以内