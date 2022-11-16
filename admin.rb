require("bundler/setup")
require("faye/websocket")
require("eventmachine")
require("permessage_deflate")
require("json")
class Client < Struct.new(:data)
  def execute
    EM.run do
      url = "ws://0.0.0.0:7001"
      ws = Faye::WebSocket::Client.new(url, [], :extensions => ([PermessageDeflate]))
      ws.onopen = lambda { |event| ws.send(data.to_json) }
      ws.onclose = lambda { |close| EM.stop }
      ws.onmessage = lambda do |message|
        data = JSON.parse(message.data)
        p(data)
        ws.close
      end
    end
  end
end

command = (ARGV[0] or "add")
@data = nil
case command
when "add" then
  channel = (ARGV[1] or "success")
  @data = { "type" => "add", "channel" => channel, "data" => "data please" }
when "list" then
  @data = { "type" => "list" }
when "retry" then
  @data = { "type" => "retry" }
end
client = Client.new(@data)
client.execute
