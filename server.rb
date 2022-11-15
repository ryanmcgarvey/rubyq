require("bundler/setup")
port = (ARGV[0] or 7001)
require(File.expand_path("../app", "(string)"))
Faye::WebSocket.load_adapter("thin")
thin = Rack::Handler.get("thin")
thin.run(App, :Host => "0.0.0.0", :Port => port) { |server| }
