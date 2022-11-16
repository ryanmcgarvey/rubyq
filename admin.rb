require("bundler/setup")
require("faye/websocket")
require("eventmachine")
require("permessage_deflate")
require("json")
class Client < Struct.new(:channel)
  def execute
    EM.run do
      url = "ws://0.0.0.0:7001"
      ws = Faye::WebSocket::Client.new(url, [], :extensions => ([PermessageDeflate]))
      ws.onopen = lambda do |event|
        data = { "channel" => channel, "type" => "add", "data" => "the data" }
        p(data)
        ws.send(data.to_json)
        ws.close
      end
      ws.onclose = lambda { |close| EM.stop }
    end
  end
end

channel = (ARGV[0] or "success")
client = Client.new(channel)
client.execute
