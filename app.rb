require("faye/websocket")
require("permessage_deflate")
require("rack")
require("json")
static = Rack::File.new(File.dirname("(string)"))
options = { :extensions => ([PermessageDeflate]), :ping => 5 }
class Subscription
  attr_reader(:name, :ws, :channel)

  def initialize(name, ws, channel)
    @name = name
    @ws = ws
    @channel = channel
  end
end

subscriptions = {}
class Event
  attr_accessor(:channel, :data, :id)

  def initialize(channel, data)
    @channel = channel
    @data = data
  end
end

class EventLog
  def initialize
    @events = []
  end

  def add(event)
    event.id = @events.length
    @events.push(event)
  end

  def get
    @events
  end
end

event_log = EventLog.new
def update_subscriptions(subscriptions, event)
  subscriptions.each do |name, subscription|
    subscription.ws.send(event.data) if (subscription.channel == event.channel)
  end
end
App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env, ["irc", "xmpp"], options)
    ws.onmessage = lambda do |wsevent|
      data = JSON.parse(wsevent.data)
      p(data)
      type = data["type"]
      case type
      when "subscribe" then
        subscriptions[data["name"]] = Subscription.new(data["name"], ws, data["channel"])
        p(subscriptions.values.map { |s| s.channel })
      when "admin" then
        event = Event.new(data["channel"], data["data"])
        event_log.add(event)
        update_subscriptions(subscriptions, event)
        ws.send({ "type" => "success" }.to_json)
      when "success" then
        p("success #{event.data["id"]}")
      when "error" then
        p("error #{event.data["id"]}")
      else
        ws.send({ "type" => "error", "message" => ("Command not recognized: #{event.data["type"]}") }.to_json)
      end
    end
    ws.onclose = lambda do |event|
      p([:close, event.code, event.reason])
      ws = nil
    end
    ws.rack_response
  else
    static.call(env)
  end
end
def (App).log(message)
  # do nothing
end
