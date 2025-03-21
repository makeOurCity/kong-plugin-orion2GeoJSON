local cjson = require "cjson"

local OrionGeoJSONHandler = {
  PRIORITY = 1000,
  VERSION = "0.1.0",
}

-- ヘルパー関数: ダミーデータの生成
local function generate_dummy_data(error_type, original_data, details)
  return {
    type = "Feature",
    geometry = {
      type = "Point",
      coordinates = {0, 0}
    },
    properties = {
      error = error_type,
      details = details or "",
      original_data = original_data
    }
  }
end

-- ヘルパー関数: 単一エンティティの変換
local function convert_single_entity(entity, conf)
  -- entity_typeの検証
  if not entity.type or entity.type ~= conf.entity_type then
    return generate_dummy_data(
      "invalid_entity_type",
      entity,
      string.format("Expected type '%s', got '%s'", conf.entity_type, entity.type or "nil")
    )
  end

  -- location_attrの検証と変換
  if not entity[conf.location_attr] then
    return generate_dummy_data(
      "location_attr_not_found",
      entity,
      string.format("Attribute '%s' not found", conf.location_attr)
    )
  end

  local location = entity[conf.location_attr]
  if type(location) ~= "table" or location.type ~= "geo:json" or not location.value then
    return generate_dummy_data(
      "invalid_location_format",
      entity,
      string.format("Invalid format for location attribute '%s'", conf.location_attr)
    )
  end

  -- プロパティの抽出
  local properties = {}
  for attr_name, attr in pairs(entity) do
    if type(attr) == "table" and attr.value and attr_name ~= conf.location_attr then
      properties[attr_name] = attr.value
    end
  end

  return {
    type = "Feature",
    geometry = location.value,
    properties = properties
  }
end

-- ヘルパー関数: エンティティ配列の変換
local function convert_entity_array(entities, conf)
  if conf.output_format == "Feature" then
    -- 最初のエンティティのみを変換
    return convert_single_entity(entities[1] or {}, conf)
  end

  -- FeatureCollection形式での変換
  local features = {}
  for _, entity in ipairs(entities) do
    table.insert(features, convert_single_entity(entity, conf))
  end

  return {
    type = "FeatureCollection",
    features = features
  }
end

function OrionGeoJSONHandler:header_filter(conf)
  kong.response.set_header("Content-Type", "application/geo+json")
end

function OrionGeoJSONHandler:body_filter(conf)
  local _, eof = ngx.arg[1], ngx.arg[2]
  if not eof then
    return
  end

  -- レスポンスボディの取得と解析
  local body = kong.response.get_raw_body()
  local success, data = pcall(cjson.decode, body)
  if not success then
    -- JSONパースエラーの場合はダミーデータを返す
    local dummy = generate_dummy_data("invalid_json", { error = "Failed to parse JSON" })
    ngx.arg[1] = cjson.encode(dummy)
    return
  end

  -- データ形式に応じた変換
  local result
  if type(data) == "table" and data[1] then
    -- 配列の場合
    result = convert_entity_array(data, conf)
  else
    -- 単一エンティティの場合
    result = convert_single_entity(data, conf)
  end

  ngx.arg[1] = cjson.encode(result)
end

return OrionGeoJSONHandler