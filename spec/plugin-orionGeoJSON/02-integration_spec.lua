local helpers = require "spec.helpers"
local PLUGIN_NAME = "orion2GeoJSON"

describe(PLUGIN_NAME .. ": (integration)", function()
  local client

  setup(function()
    -- テスト環境のセットアップ
    local bp = helpers.get_db_utils()

    -- サービスの作成
    local service = bp.services:insert({
      name = "orion",
      url = "http://orion:1026"  -- Orion Context Brokerのアドレス
    })

    -- ルートの作成
    local route = bp.routes:insert({
      service = { id = service.id },
      paths = { "/orion" }
    })

    -- プラグインの設定
    bp.plugins:insert({
      name = PLUGIN_NAME,
      route = { id = route.id },
      config = {
        entity_type = "Room",
        location_attr = "location",
        output_format = "FeatureCollection"
      }
    })

    -- Kongの起動（プラグインを有効化）
    assert(helpers.start_kong({
      database = "postgres",
      plugins = "bundled," .. PLUGIN_NAME,
      custom_plugins = PLUGIN_NAME
    }))

    -- HTTPクライアントの初期化
    client = helpers.proxy_client()
  end)

  before_each(function()
    -- 各テストケース前にエンティティをクリーンアップ
    local res = assert(client:send({
      method = "DELETE",
      path = "/orion/v2/entities?type=Room"
    }))
    assert.res_status(204, res)
  end)

  describe("単一エンティティ", function()
    it("エンティティを作成して変換結果を確認", function()
      -- エンティティの作成
      local res = assert(client:send({
        method = "POST",
        path = "/orion/v2/entities",
        headers = {
          ["Content-Type"] = "application/json"
        },
        body = {
          id = "TestRoom1",
          type = "Room",
          temperature = {
            value = 23,
            type = "Float"
          },
          location = {
            value = {
              type = "Point",
              coordinates = {13.3986112, 52.554699}
            },
            type = "geo:json"
          }
        }
      }))
      assert.res_status(201, res)

      -- 変換結果の取得と確認
      local res = assert(client:send({
        method = "GET",
        path = "/orion/v2/entities/TestRoom1",
        query = { type = "Room" }
      }))
      assert.res_status(200, res)
      
      local body = assert.response(res).has.jsonbody()
      assert.equals("Feature", body.type)
      assert.equals("Point", body.geometry.type)
      assert.same({13.3986112, 52.554699}, body.geometry.coordinates)
      assert.equals(23, body.properties.temperature)
    end)
  end)

  describe("複数エンティティ", function()
    it("複数エンティティの作成と取得", function()
      -- 複数のテストエンティティを作成
      for i = 1, 3 do
        local res = assert(client:send({
          method = "POST",
          path = "/orion/v2/entities",
          headers = {
            ["Content-Type"] = "application/json"
          },
          body = {
            id = "TestRoom" .. i,
            type = "Room",
            location = {
              value = {
                type = "Point",
                coordinates = {13.3986112 + i*0.0001, 52.554699 + i*0.0001}
              },
              type = "geo:json"
            }
          }
        }))
        assert.res_status(201, res)
      end

      -- 全エンティティの取得
      local res = assert(client:send({
        method = "GET",
        path = "/orion/v2/entities",
        query = { type = "Room" }
      }))
      assert.res_status(200, res)
      
      local body = assert.response(res).has.jsonbody()
      assert.equals("FeatureCollection", body.type)
      assert.equals(3, #body.features)
    end)

    it("クエリパラメータの処理", function()
      -- limit=2のテスト
      local res = assert(client:send({
        method = "GET",
        path = "/orion/v2/entities",
        query = { 
          type = "Room",
          limit = 2
        }
      }))
      assert.res_status(200, res)
      
      local body = assert.response(res).has.jsonbody()
      assert.equals(2, #body.features)
    end)
  end)

  describe("エラーケース", function()
    it("存在しないエンティティ", function()
      local res = assert(client:send({
        method = "GET",
        path = "/orion/v2/entities/NonExistent",
        query = { type = "Room" }
      }))
      assert.res_status(404, res)
    end)

    it("タイプ不一致", function()
      -- まずエンティティを作成
      local res = assert(client:send({
        method = "POST",
        path = "/orion/v2/entities",
        headers = {
          ["Content-Type"] = "application/json"
        },
        body = {
          id = "TestRoom1",
          type = "Room",
          location = {
            value = {
              type = "Point",
              coordinates = {13.3986112, 52.554699}
            },
            type = "geo:json"
          }
        }
      }))
      assert.res_status(201, res)

      -- 誤ったタイプで取得を試みる
      res = assert(client:send({
        method = "GET",
        path = "/orion/v2/entities/TestRoom1",
        query = { type = "Wrong" }
      }))
      assert.res_status(404, res)
    end)
  end)

  describe("レスポンスヘッダー", function()
    it("Content-Typeの確認", function()
      local res = assert(client:send({
        method = "GET",
        path = "/orion/v2/entities",
        query = { type = "Room" }
      }))
      assert.res_status(200, res)
      assert.equals("application/geo+json", res.headers["Content-Type"])
    end)
  end)

  teardown(function()
    if client then client:close() end
    helpers.stop_kong()
  end)
end)