require("faye/websocket")
require("permessage_deflate")
require("rack")
require("json")
require_relative("lib/message")
static = Rack::File.new(File.dirname("(string)"))
options = { :extensions => ([PermessageDeflate]), :ping => 5 }
message_handler = MessageHandler.new
App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, ["irc", "xmpp"], options)
    ws.onmessage = lambda do |wsevent|
      data = JSON.parse(wsevent.data)
      message_handler.process_message(ws, data)
    end
    ws.onclose = lambda { |event| ws = nil }
    ws.rack_response
  else
    static.call(env)
  end
end
def (App).log(message)
  # do nothing
end
