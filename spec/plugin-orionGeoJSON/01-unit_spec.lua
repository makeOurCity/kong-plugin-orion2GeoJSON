local PLUGIN_NAME = "orion2GeoJSON"
local cjson = require "cjson"
local handler = require("kong.plugins." .. PLUGIN_NAME .. ".handler")

-- ヘルパー関数
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins." .. PLUGIN_NAME .. ".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

-- テストデータ
local sample_entity = {
  id = "Room1",
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

local sample_entity_array = {
  {
    id = "Room1",
    type = "Room",
    location = {
      value = {
        type = "Point",
        coordinates = {13.3986112, 52.554699}
      },
      type = "geo:json"
    }
  },
  {
    id = "Room2",
    type = "Room",
    location = {
      value = {
        type = "Point",
        coordinates = {13.3986113, 52.554700}
      },
      type = "geo:json"
    }
  }
}

-- モック設定
local function setup_kong_mock()
  _G.ngx = {
    arg = {},
    ctx = {}
  }
  _G.kong = {
    response = {
      set_header = function() end,
      get_raw_body = function() return cjson.encode(sample_entity) end
    },
    log = {
      debug = function() end
    }
  }
end

describe(PLUGIN_NAME .. ": (schema)", function()
  it("validates minimal config with FeatureCollection format", function()
    local ok, err = validate({
      output_format = "FeatureCollection"
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("validates minimal config with Feature format", function()
    local ok, err = validate({
      output_format = "Feature"
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("rejects invalid output_format", function()
    local ok, err = validate({
      output_format = "InvalidFormat"
    })
    assert.is_falsy(ok)
    assert.is_table(err)
  end)
end)

describe(PLUGIN_NAME .. ": (handler)", function()
  local plugin_handler

  before_each(function()
    setup_kong_mock()
    plugin_handler = handler
  end)

  describe("body_filter()", function()
    it("converts single entity to Feature", function()
      _G.kong.response.get_raw_body = function()
        return cjson.encode(sample_entity)
      end
      _G.ngx.arg = {"", true}

      plugin_handler:body_filter({ output_format = "Feature" })

      local result = cjson.decode(ngx.arg[1])
      assert.equals("Feature", result.type)
      assert.equals("Point", result.geometry.type)
      assert.same({13.3986112, 52.554699}, result.geometry.coordinates)
      assert.equals(23, result.properties.temperature)
    end)

    it("converts entity array to FeatureCollection", function()
      _G.kong.response.get_raw_body = function()
        return cjson.encode(sample_entity_array)
      end
      _G.ngx.arg = {"", true}

      plugin_handler:body_filter({ output_format = "FeatureCollection" })

      local result = cjson.decode(ngx.arg[1])
      assert.equals("FeatureCollection", result.type)
      assert.equals(2, #result.features)
      assert.equals("Point", result.features[1].geometry.type)
    end)

    it("returns dummy data when no geo:json attribute found", function()
      local entity_without_location = {
        id = "Room1",
        type = "Room",
        temperature = {
          value = 23,
          type = "Float"
        }
      }

      _G.kong.response.get_raw_body = function()
        return cjson.encode(entity_without_location)
      end
      _G.ngx.arg = {"", true}

      plugin_handler:body_filter({ output_format = "Feature" })

      local result = cjson.decode(ngx.arg[1])
      assert.equals("Feature", result.type)
      assert.equals("Point", result.geometry.type)
      assert.same({0, 0}, result.geometry.coordinates)
      assert.equals("conversion_failed", result.properties.error)
    end)
  end)

  describe("header_filter()", function()
    it("sets correct content type", function()
      local header_set = false
      _G.kong.response.set_header = function(name, value)
        if name == "Content-Type" and value == "application/geo+json" then
          header_set = true
        end
      end

      plugin_handler:header_filter({})
      assert.is_true(header_set)
    end)
  end)
end)