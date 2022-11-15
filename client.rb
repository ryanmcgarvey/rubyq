require("bundler/setup")
require("faye/websocket")
require("eventmachine")
require("permessage_deflate")
name = (ARGV[0] or "default")
class Client
  attr_reader(:name)

  def initialize(name)
    @name = name
  end

  def listen
    EM.run do
      url = "ws://0.0.0.0:7001"
      ws = Faye::WebSocket::Client.new(url, [], :extensions => ([PermessageDeflate]))
      ws.onopen = lambda { |event| ws.send("mic check") }
      ws.onclose = lambda do |close|
        p([:close, close.code, close.reason])
        EM.stop
      end
      ws.onerror = lambda { |error| p([:error, error.message]) }
      ws.onmessage = lambda { |message| p([:message, message.data]) }
    end
  end
end

client = Client.new(name)
