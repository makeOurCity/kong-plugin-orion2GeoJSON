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
              match = "^[a-zA-Z0-9_-]+$",
              match_error = "must only contain alphanumeric characters, hyphens, and underscores"
            }
          },
          { location_attr = {
              type = "string",
              required = true,
              match = "^[a-zA-Z0-9_-]+$",
              match_error = "must only contain alphanumeric characters, hyphens, and underscores"
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
              default = false
            }
          }
        }
      }
    }
  }
}