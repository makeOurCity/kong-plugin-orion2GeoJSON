local typedefs = require "kong.db.schema.typedefs"

return {
  name = "orion2GeoJSON",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { output_format = {
              type = "string",
              required = true,
              default = "FeatureCollection",
              one_of = { "FeatureCollection", "Feature" }
            }
          }
        }
      }
    }
  }
}