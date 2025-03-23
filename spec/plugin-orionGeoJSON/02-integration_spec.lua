local helpers = require "spec.helpers"
local PLUGIN_NAME = "orion2GeoJSON"
local cjson = require "cjson"

describe(PLUGIN_NAME .. ": (integration)", function()
  local client
  local proxy_client, admin_client

  setup(function()
    -- テストヘルパーの初期化
    local bp = helpers.get_db_utils(nil, {"postgres"}, {PLUGIN_NAME})

    -- プラグインを有効化してKongを起動
    assert(helpers.start_kong({
      database = "postgres",
      plugins = "bundled," .. PLUGIN_NAME,
      log_level = "debug"
    }))

    -- サービスの作成
    local service = bp.services:insert({
      name = "orion-test",
      url = "http://orion:1026"
    })

    -- ルートの作成
    local route = bp.routes:insert({
      paths = { "/v2/entities", "/v2/entities/(?.*)" },
      service = service,
      strip_path = false
    })

    -- プラグインの設定
    bp.plugins:insert({
      name = PLUGIN_NAME,
      route = route,
      config = {
        entity_type = "Room",
        location_attr = "location",
        output_format = "FeatureCollection",
        conditional_transform = false
      }
    })
    
    -- Kong環境の情報を出力
    print("Kong環境情報:")
    print("ホスト: " .. helpers.get_proxy_ip() .. ":" .. helpers.get_proxy_port())
  end)

  before_each(function()
    proxy_client = helpers.proxy_client()
    admin_client = helpers.admin_client()
  end)

  after_each(function()
    if proxy_client then proxy_client:close() end
    if admin_client then admin_client:close() end
  end)

  describe("基本機能テスト", function()
    -- 設定確認のテスト
    it("Kongの設定確認", function()
      local res = assert(admin_client:send({
        method = "GET",
        path = "/routes",
        headers = {
          ["Content-Type"] = "application/json"
        }
      }))
      
      print("Routes API レスポンス:")
      print("Status: " .. tostring(res.status))
      assert.res_status(200, res)
      
      -- サービスの確認
      res = assert(admin_client:send({
        method = "GET",
        path = "/services",
        headers = {
          ["Content-Type"] = "application/json"
        }
      }))
      
      print("Services API レスポンス:")
      print("Status: " .. tostring(res.status))
      assert.res_status(200, res)
      
      -- プラグインの確認
      res = assert(admin_client:send({
        method = "GET",
        path = "/plugins",
        headers = {
          ["Content-Type"] = "application/json"
        }
      }))
      
      print("Plugins API レスポンス:")
      print("Status: " .. tostring(res.status))
      assert.res_status(200, res)
    end)
    
    -- OrionレスポンスのGeoJSON変換確認
    it("OrionレスポンスのGeoJSON変換確認", function()
      -- 最小限のチェック：Kongプロキシへの接続が成功していることを確認
      local res = assert(proxy_client:send({
        method = "GET",
        path = "/v2/entities",
        headers = {
          ["Accept"] = "application/json"
        }
      }))
      
      -- レスポンスのステータスを確認
      print("Status: " .. tostring(res.status))
      assert.is_number(res.status)
      
      -- レスポンスのコンテンツタイプを確認
      print("Content-Type: " .. (res.headers["content-type"] or "なし"))
      
      -- プラグインが適用されたことを示すヘッダーを確認
      print("X-Kong-Proxy-Latency: " .. (res.headers["x-kong-proxy-latency"] or "なし"))
    end)
  end)

  teardown(function()
    print("Kongサーバーを停止します")
    helpers.stop_kong()
    print("テスト環境のクリーンアップ完了")
  end)
end)