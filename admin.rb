require("bundler/setup")
require("faye/websocket")
require("eventmachine")
require("permessage_deflate")
require("json")
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
      ws.onopen = lambda do |event|
        data = { "channel" => name, "type" => "admin", "data" => "the data" }
        p(data)
        ws.send(data.to_json)
      end
      ws.onclose = lambda { |close| EM.stop }
      ws.onerror = lambda do |error|
        p([:error, error.message])
        EM.stop
      end
      ws.onmessage = lambda { |message| ws.close }
    end
  end
end

client = Client.new(name)
client.listen
