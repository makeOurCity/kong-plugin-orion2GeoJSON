package = "plugin-orion2GeoJSON"
version = "0.1.0-1"
source = {
   url = "git://github.com/kzkski/plugin-orion2GeoJSON",
   tag = "0.1.0"
}

description = {
   summary = "A Kong plugin that converts FIWARE Orion responses to GeoJSON format",
   detailed = [[
      This Kong plugin intercepts responses from FIWARE Orion Context Broker
      and converts them to GeoJSON format for geographic visualization.
   ]],
   homepage = "https://github.com/kzkski/plugin-orion2GeoJSON",
   license = "Apache 2.0"
}

dependencies = {
   "lua >= 5.1",
   "lua-cjson >= 2.1"
}

build = {
   type = "builtin",
   modules = {
      ["kong.plugins.plugin-orionGeoJSON.handler"] = "kong/plugins/plugin-orionGeoJSON/handler.lua",
      ["kong.plugins.plugin-orionGeoJSON.schema"] = "kong/plugins/plugin-orionGeoJSON/schema.lua"
   }
}