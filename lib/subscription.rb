class Subscription
  attr_reader(:ws, :channels)

  def initialize(ws, channels)
    @ws = ws
    @channels = channels
  end
end

class Job
  attr_accessor(:event_id, :status, :time)

  def initialize(event_id, status, time)
    @event_id = event_id
    @status = status
    @time = time
  end

  def needs_retry
    ["timeout", "error"].include?(status)
  end

  def as_json
    { "event_id" => event_id, "status" => status, "time" => time }
  end

  def to_json
    as_json.to_json
  end
end

class SubscriptionManager
  attr_reader(:subscriptions, :jobs)

  def initialize
    @subscriptions = {}
    @jobs = {}
  end

  def add_subscription(ws, data)
    channels = data["channels"]
    channels.each do |channel|
      if (subscriptions[channel] == nil)
        subscriptions[channel] = Subscription.new(ws, channels)
      else
        subscriptions[channel] = Subscription.new(ws, channels)
      end
    end
  end

  def update_subscriptions(event)
    subscription = subscriptions[event.channel]
    if subscription
      subscription.ws.send(event.to_json)
      jobs[event.id] = Job.new(event.id, "sent", Time.now)
      process_timeout(event.id)
    end
  end

  def process_timeout(event_id)
    Thread.new do
      sleep(5)
      if (jobs[event_id].status == "sent")
        jobs[event_id].status = "timeout"
        p("timeout #{event_id}")
      end
    end
  end

  def job_succeeded(event_id)
    jobs[event_id].status = "success"
    p("success #{event_id}")
  end

  def job_failed(event_id)
    jobs[event_id].status = "error"
    p("error #{event_id}")
  end
end
