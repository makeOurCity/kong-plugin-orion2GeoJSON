local typedefs = require "kong.db.schema.typedefs"

return {
  name = "orion2GeoJSON",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { entity_type = {
              type = "string",
              required = true,
              default = "Room"
            }
          },
          { location_attr = {
              type = "string",
              required = true,
              default = "location"
            }
          },
          { output_format = {
              type = "string",
              required = true,
              default = "FeatureCollection",
              one_of = { "FeatureCollection", "Feature" }
            }
          },
          { conditional_transform = {
              type = "boolean",
              required = true,
              default = true
            }
          }
        }
      }
    }
  }
}