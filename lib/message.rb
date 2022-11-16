require_relative("event")
require_relative("subscription")
class MessageHandler
  attr_reader(:manager, :event_log)

  def initialize
    @event_log = EventLog.new
    @manager = SubscriptionManager.new(event_log)
  end

  def process_message(ws, data)
    unless data
      ws.send({ "type" => "error", "message" => "Command not recognized" }.to_json)
      return
    end
    case data["type"]
    when "subscribe" then
      manager.add_subscription(ws, data)
    when "add" then
      event = Event.new(data["channel"], data["data"])
      event_log.add(event)
      p("New Event: #{event.channel} - #{event.id}")
      manager.update_subscriptions(event)
      ws.send({ "type" => "success" }.to_json)
    when "list" then
      events = manager.jobs.map { |id, job| job.as_json }
      ws.send({ "type" => "list", "events" => events }.to_json)
    when "retry" then
      jobs = manager.jobs.values.select { |job| job.needs_retry }
      jobs.each { |job| manager.update_subscriptions(event_log.get[job.event_id]) }
      ws.send({ "type" => "success", "jobs" => jobs.size }.to_json)
    when "success" then
      manager.job_succeeded(data["id"])
    when "error" then
      manager.job_failed(data["id"])
    else
      ws.send({ "type" => "error", "message" => ("Command not recognized: #{event.data["type"]}") }.to_json)
    end
  end
end
