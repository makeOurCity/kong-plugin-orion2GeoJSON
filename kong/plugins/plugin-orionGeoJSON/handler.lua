local CustomHandler = {
  PRIORITY = 1000,
  VERSION = "0.1.0",
}

function CustomHandler:init_worker()
  -- Executed when Kong starts
  kong.log.debug("Initializing plugin")
end

function CustomHandler:access(conf)
  -- Executed for each request, before it is proxied to the upstream service
  kong.log.debug("Processing request")
end

function CustomHandler:header_filter(conf)
  -- Executed after receiving the response headers from the upstream service
  kong.log.debug("Processing response headers")
end

function CustomHandler:body_filter(conf)
  -- Executed after receiving the response body from the upstream service
  kong.log.debug("Processing response body")
end

function CustomHandler:log(conf)
  -- Executed after the response has been sent to the client
  kong.log.debug("Logging request")
end

return CustomHandler