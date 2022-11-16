require("bundler/setup")
require("faye/websocket")
require("eventmachine")
require("permessage_deflate")
require("json")
class Client
  def initialize(from = nil)
    @callbacks = {}
    @from = from
  end

  def on(channel, &block)
    @callbacks[channel] = block
  end

  def listen
    EM.run do
      url = "ws://0.0.0.0:7001"
      ws = Faye::WebSocket::Client.new(url, [], :extensions => ([PermessageDeflate]))
      ws.onopen = lambda do |event|
        data = { "type" => "subscribe", "channels" => @callbacks.keys, "cursor" => (@from) }.to_json
        ws.send(data)
      end
      ws.onclose = lambda { |close| EM.stop }
      ws.onerror = lambda { |error| p([:error, error.message]) }
      ws.onmessage = lambda do |message|
        Thread.new do
          data = JSON.parse(message.data)
          id = data["id"]
          channel = data["channel"]
          begin
            (response = @callbacks[channel].call(data) if @callbacks[channel]
            if response
              ws.send({ "type" => "success", "id" => id }.to_json)
            else
              ws.send({ "type" => "error", "id" => id }.to_json)
            end)
          rescue => e
            ws.send({ "type" => "error", "id" => id }.to_json)
          end
        end
      end
    end
  end
end
