require("bundler/setup")
require("faye/websocket")
require("eventmachine")
require("permessage_deflate")
require("json")
name = (ARGV[0] or "default-client")
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
        data = { "name" => name, "type" => "subscribe", "channel" => "default" }.to_json
        ws.send(data)
      end
      ws.onclose = lambda do |close|
        p([:close, close.code, close.reason])
        EM.stop
      end
      ws.onerror = lambda { |error| p([:error, error.message]) }
      ws.onmessage = lambda do |message|
        p([:message, message.data])
        data = message.data
        id = data["id"]
        if (id == 3)
          ws.send("type" => "error", "id" => id)
        else
          ws.send("type" => "success", "id" => id)
        end
      end
    end
  end
end

client = Client.new(name)
client.listen
