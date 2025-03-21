local cjson = require "cjson"
local tools = require "kong.plugins.orion2GeoJSON.tools"

local OrionGeoJSONHandler = {
  PRIORITY = 820,
  VERSION = "0.1.0",
}

-- クエリパラメータに format=geojson があるかチェックする関数
local function should_transform(conf)
  -- 設定がnilの場合の安全対策
  if not conf then
    kong.log.err("設定が存在しません")
    return false
  end
  
  -- conditional_transform が false の場合は常に変換する
  if conf.conditional_transform == false then
    kong.log.debug("条件付き変換無効: 常に変換します")
    return true
  end
  
  -- クエリパラメータの取得
  local args
  pcall(function()
    args = kong.request.get_query()
  end)
  
  -- args が取得できなかった場合
  if not args then
    kong.log.debug("クエリパラメータの取得に失敗")
    return false
  end
  
  -- format パラメータの確認
  local format = args.format
  
  -- クエリ文字列のデバッグ（可能な場合）
  local query_string = ""
  pcall(function()
    query_string = ngx.var.args or ""
  end)
  kong.log.debug("クエリ文字列: ", query_string)
  
  -- format=geojson パラメータがあるかチェック
  local has_geojson_format = format == "geojson"
  kong.log.debug("format=geojson検出: ", has_geojson_format)
  
  return has_geojson_format
end

function OrionGeoJSONHandler:access(conf)
  kong.ctx.shared = kong.ctx.shared or {}
  
  -- 変換が必要かどうかのフラグを設定
  kong.ctx.shared.transform_geo = should_transform(conf)
  kong.log.debug("access: 変換フラグ設定: ", kong.ctx.shared.transform_geo)
end

function OrionGeoJSONHandler:header_filter(conf)
  kong.log.debug("header_filter実行: プラグインID=", conf.__plugin_id)
  
  -- テスト環境では kong.ctx が存在しない場合がある
  kong.ctx = kong.ctx or {}
  kong.ctx.shared = kong.ctx.shared or {}
  
  -- テスト環境では access が実行されない場合があるので、変換フラグを設定
  if kong.ctx.shared.transform_geo == nil then
    kong.ctx.shared.transform_geo = should_transform(conf)
    kong.log.debug("header_filter: 変換フラグを設定: ", kong.ctx.shared.transform_geo)
  end
  
  -- 変換が必要な場合のみContent-Typeを変更
  if kong.ctx.shared.transform_geo then
    kong.log.debug("Content-Typeを変更: application/geo+json")
    kong.response.set_header("Content-Type", "application/geo+json")
    
    -- レスポンスボディを初期化
    kong.ctx.shared.response_body = ""
    
    -- 重要: Content-Lengthを完全に削除
    -- body_filterフェーズで新しいJSONを生成した際に
    -- Kongが正しい長さを自動計算できるようにする
    pcall(function() 
      kong.response.clear_header("Content-Length")
      kong.log.debug("Content-Lengthヘッダーを削除しました")
    end)
  else
    kong.log.debug("Content-Type変更なし: 元のまま")
  end
end

function OrionGeoJSONHandler:body_filter(conf)
  -- テスト環境では kong.ctx が存在しない場合がある
  kong.ctx = kong.ctx or {}
  kong.ctx.shared = kong.ctx.shared or {}
  
  -- テスト環境では access が実行されない場合があるので、変換フラグを設定
  if kong.ctx.shared.transform_geo == nil then
    kong.ctx.shared.transform_geo = should_transform(conf)
  end
  
  kong.log.debug("body_filter実行: プラグインID=", conf.__plugin_id)
  kong.log.debug("設定: entity_type=", conf.entity_type, ", output_format=", conf.output_format)
  
  -- 変換が必要かどうか確認
  if not kong.ctx.shared.transform_geo then
    kong.log.debug("変換不要: 元のレスポンスを返します")
    return  -- 変換不要の場合は何もせず終了（元のレスポンスがそのまま返される）
  end
  
  local chunk, eof = ngx.arg[1], ngx.arg[2]
  
  -- 完全なレスポンスボディを集めるための初期化
  if not kong.ctx.shared.response_body then
    kong.ctx.shared.response_body = ""
  end
  
  -- チャンクがある場合は追加
  if chunk and #chunk > 0 then
    kong.log.debug("チャンク受信: ", #chunk, " バイト")
    kong.ctx.shared.response_body = kong.ctx.shared.response_body .. chunk
    -- 処理途中ではチャンクを出力しない
    ngx.arg[1] = nil
  end
  
  -- 最終チャンクでない場合は処理終了
  if not eof then
    kong.log.debug("チャンク処理中断: EOFではありません")
    return
  end
  
  -- 完全なレスポンスボディを取得
  local body = kong.ctx.shared.response_body
  kong.log.debug("完全なレスポンスボディ取得: ", #body, " バイト")
  
  if not body or #body == 0 then
    kong.log.err("レスポンスボディが空です")
    ngx.arg[1] = '{"error": "Empty response body"}'
    return
  end
  
  -- JSONパース処理
  kong.log.debug("JSONパース開始")
  local success, data = pcall(function()
    kong.log.debug("JSONデコード前のボディ: " .. body:sub(1, 50) .. "...")
    return cjson.decode(body)
  end)
  
  if not success then
    kong.log.err("JSONパースエラー: ", data)
    kong.log.debug("パースエラーの発生したボディ(先頭100文字): " .. body:sub(1, 100))
    
    -- 元のボディを出力（デバッグ用）
    print("パースエラー！元のボディ長さ: " .. #body)
    print("ボディの先頭100文字: " .. body:sub(1, 100))
    print("ボディの末尾100文字: " .. body:sub(-100))
    
    ngx.arg[1] = cjson.encode({
      type = "Feature",
      properties = {
        error = "json_parse_error",
        message = tostring(data)
      },
      geometry = nil
    })
    return
  end
  
  kong.log.debug("JSONパース成功: データタイプ=", type(data))
  
  -- データがテーブルかどうか確認
  if type(data) ~= "table" then
    kong.log.err("期待されるデータタイプはtableですが、", type(data), "が見つかりました")
    ngx.arg[1] = cjson.encode({
      type = "Feature",
      properties = {
        error = "invalid_data_type",
        message = "Expected table but got " .. type(data)
      },
      geometry = nil
    })
    return
  end
  
  -- 配列の検出ロジックを改善
  local is_array = false
  local array_length = 0
  
  -- まず、数値キーが存在するかチェック
  if data[1] ~= nil then
    is_array = true
    -- 長さを取得
    for i, _ in ipairs(data) do
      array_length = i
    end
  end
  
  kong.log.debug("配列検出: ", is_array, ", 長さ: ", array_length)
  
  -- 出力形式を決定
  local requested_format = conf.output_format or "Feature"
  kong.log.debug("リクエストされた出力形式: ", requested_format)
  
  -- データに基づいて処理法を決定
  local result
  if is_array then
    -- 配列データの場合
    kong.log.debug("配列データを処理: 要素数=", array_length)
    if requested_format == "FeatureCollection" or array_length > 1 then
      -- FeatureCollectionが要求された、または複数要素の配列
      kong.log.debug("FeatureCollection形式で変換")
      result = tools.convert_entity_array(data, conf)
    else
      -- 単一要素の配列で出力形式がFeatureの場合
      kong.log.debug("単一要素の配列を単一エンティティとして変換")
      result = tools.convert_single_entity(data[1], conf)
    end
  else
    -- 単一オブジェクトの場合
    kong.log.debug("単一エンティティを処理")
    if requested_format == "FeatureCollection" then
      -- FeatureCollectionが要求された場合
      kong.log.debug("単一エンティティをFeatureCollection形式で変換")
      local feature = tools.convert_single_entity(data, conf)
      result = {
        type = "FeatureCollection",
        features = {feature},
        metadata = {
          count = 1
        }
      }
    else
      -- 通常のFeature出力
      kong.log.debug("単一エンティティをFeature形式で変換")
      result = tools.convert_single_entity(data, conf)
    end
  end
  
  -- 結果の型を確認
  kong.log.debug("結果の型: ", result.type)
  
  -- 結果のエンコードと出力
  local json_result = cjson.encode(result)
  kong.log.debug("変換結果: ", #json_result, " バイト")
  ngx.arg[1] = json_result
  
  -- Content-Lengthヘッダーの更新は行わない（Kongが自動的に処理する）
end

return OrionGeoJSONHandler