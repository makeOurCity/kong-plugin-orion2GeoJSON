local cjson = require "cjson"

local OrionGeoJSONHandler = {
  PRIORITY = 1000,
  VERSION = "0.1.0",
}

-- ヘルパー関数: ダミーデータの生成
local function generate_dummy_data(original_data)
  return {
    type = "Feature",
    geometry = {
      type = "Point",
      coordinates = {0, 0}
    },
    properties = {
      error = "conversion_failed",
      original_data = original_data
    }
  }
end

-- ヘルパー関数: 単一エンティティの変換
local function convert_single_entity(entity)
  local geometries = {}
  local properties = {}

  for attr_name, attr in pairs(entity) do
    if type(attr) == "table" and attr.type == "geo:json" then
      geometries[attr_name] = attr.value
    elseif type(attr) == "table" and attr.value then
      properties[attr_name] = attr.value
    end
  end

  -- geo:json属性が見つからない場合はダミーデータを返す
  if not next(geometries) then
    return generate_dummy_data(entity)
  end

  -- 最初に見つかったgeo:json属性を使用
  local geometry_name, geometry = next(geometries)
  return {
    type = "Feature",
    geometry = geometry,
    properties = properties
  }
end

-- ヘルパー関数: エンティティ配列の変換
local function convert_entity_array(entities, output_format)
  if output_format == "Feature" then
    -- 最初のエンティティのみを変換
    return convert_single_entity(entities[1] or {})
  end

  -- FeatureCollection形式での変換
  local features = {}
  for _, entity in ipairs(entities) do
    table.insert(features, convert_single_entity(entity))
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
  local chunk, eof = ngx.arg[1], ngx.arg[2]
  if not eof then
    return
  end

  -- レスポンスボディの取得と解析
  local body = kong.response.get_raw_body()
  local success, data = pcall(cjson.decode, body)
  if not success then
    -- JSONパースエラーの場合はダミーデータを返す
    local dummy = generate_dummy_data({ error = "invalid_json" })
    ngx.arg[1] = cjson.encode(dummy)
    return
  end

  -- データ形式に応じた変換
  local result
  if type(data) == "table" and data[1] then
    -- 配列の場合
    result = convert_entity_array(data, conf.output_format)
  else
    -- 単一エンティティの場合
    result = convert_single_entity(data)
  end

  ngx.arg[1] = cjson.encode(result)
end

return OrionGeoJSONHandler