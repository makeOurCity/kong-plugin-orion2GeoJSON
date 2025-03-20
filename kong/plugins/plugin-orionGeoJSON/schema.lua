local typedefs = require "kong.db.schema.typedefs"

return {
  name = "custom-plugin",
  fields = {
    -- デフォルトのプラグインフィールド
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          -- ここにプラグイン固有の設定フィールドを追加
          {
            example_field = {
              type = "string",
              required = true,
              default = "default value"
            }
          }
        }
      }
    }
  }
}