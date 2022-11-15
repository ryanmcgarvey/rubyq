require("bundler/setup")
require(File.expand_path("../app", "(string)"))
Faye::WebSocket.load_adapter("thin")
run(App)
