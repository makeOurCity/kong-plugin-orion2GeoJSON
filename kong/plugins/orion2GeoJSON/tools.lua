-- エラー発生時のダミーデータを生成する関数
local function generate_dummy_data(error_type, details)
  -- エラー情報を含むFeature形式のデータを返す
  local result = {
    type = "Feature",
    properties = {
      error = error_type,
      details = details
    },
    geometry = nil
  }
  return result
end

-- エンティティからFeatureを作成する関数
local function generate_feature(entity, config)
  -- エンティティのタイプ確認
  if entity.type ~= config.entity_type then
    return generate_dummy_data("invalid_entity_type", { expected = config.entity_type, got = entity.type })
  end
  
  -- 位置情報の確認
  if not entity[config.location_attr] or 
     not entity[config.location_attr].value or
     not entity[config.location_attr].value.type or
     not entity[config.location_attr].value.coordinates then
    return generate_dummy_data("missing_location", { entity_id = entity.id })
  end
  
  -- プロパティの抽出
  local properties = {}
  for key, value in pairs(entity) do
    if key ~= config.location_attr and type(value) == "table" and value.value ~= nil then
      properties[key] = value.value
    end
  end
  
  -- Featureの作成
  local feature = {
    type = "Feature",
    id = entity.id,
    geometry = {
      type = entity[config.location_attr].value.type,
      coordinates = entity[config.location_attr].value.coordinates
    },
    properties = properties
  }
  
  return feature
end

-- 単一エンティティをFeatureに変換する関数
local function convert_single_entity(entity, config)
  if type(entity) ~= "table" then
    return generate_dummy_data("invalid_data_type", { error = "Expected table but got " .. type(entity) })
  end
  
  return generate_feature(entity, config)
end

-- エンティティ配列をFeatureCollectionに変換する関数
local function convert_entity_array(entities, config)
  if type(entities) ~= "table" then
    kong.log.err("エンティティ配列が無効です: " .. type(entities))
    return generate_dummy_data("invalid_data_type", { error = "Expected table but got " .. type(entities) })
  end
  
  -- 配列かどうかをより厳密に判定
  local is_array = false
  local array_length = 0
  
  -- ipairsが動作するかどうかで配列かチェック
  for i, _ in ipairs(entities) do
    is_array = true
    array_length = array_length > i and array_length or i
  end
  
  kong.log.debug("配列検出: " .. tostring(is_array) .. ", 長さ: " .. array_length)
  
  -- 単一エンティティの場合は単一変換を使用（出力形式がFeatureCollectionの場合を除く）
  if not is_array and entities.id then
    kong.log.debug("単一エンティティを検出: " .. entities.id)
    
    -- 出力形式がFeatureCollectionの場合
    if config.output_format == "FeatureCollection" then
      kong.log.debug("単一エンティティを強制的にFeatureCollectionに変換")
      local feature = convert_single_entity(entities, config)
      
      -- 単一Featureを含むFeatureCollectionを返す
      return {
        type = "FeatureCollection",
        features = {feature},
        metadata = {
          count = 1,
          errors = 0
        }
      }
    else
      -- 単一エンティティ変換を使用
      kong.log.debug("単一エンティティを変換")
      return convert_single_entity(entities, config)
    end
  end
  
  -- 配列データをFeatureCollectionに変換
  kong.log.debug("FeatureCollection形式に変換: 要素数=" .. array_length)
  local features = {}
  local error_count = 0
  
  -- 通常の配列処理
  for i, entity in ipairs(entities) do
    kong.log.debug("エンティティ " .. i .. " を処理中")
    if entity.type ~= config.entity_type then
      -- エンティティタイプが一致しない場合はスキップしてエラーカウント
      kong.log.debug("エンティティタイプが不一致: " .. (entity.type or "nil") .. " != " .. config.entity_type)
      error_count = error_count + 1
    elseif not entity[config.location_attr] or 
           not entity[config.location_attr].value or
           not entity[config.location_attr].value.coordinates then
      -- 位置情報が不正な場合はスキップしてエラーカウント
      kong.log.debug("位置情報が無効")
      error_count = error_count + 1
    else
      kong.log.debug("エンティティを Feature に変換")
      local feature = generate_feature(entity, config)
      table.insert(features, feature)
    end
  end
  
  -- FeatureCollection 型を強制
  local result = {
    type = "FeatureCollection",
    features = features,
    metadata = {
      count = #features,
      errors = error_count > 0 and error_count or nil
    }
  }
  
  kong.log.debug("結果の type: " .. result.type)
  kong.log.debug("features 数: " .. #result.features)
  
  return result
end

-- モジュールのエクスポート
return {
  convert_single_entity = convert_single_entity,
  convert_entity_array = convert_entity_array,
  generate_dummy_data = generate_dummy_data
} 