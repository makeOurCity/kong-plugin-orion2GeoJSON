local PLUGIN_NAME = "orion2GeoJSON"

-- helper function to validate data against schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins." .. PLUGIN_NAME .. ".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

describe(PLUGIN_NAME .. ": (schema)", function()
  it("validates minimal config", function()
    local ok, err = validate({
      example_field = "test value"
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("validates required fields", function()
    local ok, err = validate({})
    assert.is_nil(ok)
    assert.is_table(err)
    assert.equals("required field missing", err.config.example_field)
  end)
end)