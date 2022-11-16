require_relative("event")
require_relative("subscription")
class MessageHandler
  attr_reader(:manager, :event_log)

  def initialize
    @manager = SubscriptionManager.new
    @event_log = EventLog.new
  end

  def process_message(ws, data)
    case data["type"]
    when "subscribe" then
      manager.add_subscription(ws, data)
    when "add" then
      event = Event.new(data["channel"], data["data"])
      event_log.add(event)
      p("New Event: #{event.channel} - #{event.id}")
      manager.update_subscriptions(event)
      ws.send({ "type" => "success" }.to_json)
    when "success" then
      manager.job_succeeded(data["id"])
    when "error" then
      manager.job_failed(data["id"])
    else
      ws.send({ "type" => "error", "message" => ("Command not recognized: #{event.data["type"]}") }.to_json)
    end
  end
end
