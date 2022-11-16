class Subscription
  attr_reader(:ws, :channels)

  def initialize(ws, channels)
    @ws = ws
    @channels = channels
  end
end

class Job
  attr_accessor(:event_id, :status, :time, :ws)

  def initialize(event_id, status, time, ws)
    @event_id = event_id
    @status = status
    @time = time
    @ws = ws
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
  attr_reader(:subscriptions, :jobs, :event_log)

  def initialize(event_log)
    @event_log = event_log
    @subscriptions = {}
    @jobs = {}
    @sockets = {}
  end

  def add_subscription(ws, data)
    channels = data["channels"]
    channels.each do |channel|
      if (subscriptions[channel] == nil)
        subscriptions[channel] = Subscription.new(ws, channels)
        cursor = data["cursor"]
        if (cursor != nil)
          event_log.from(cursor.to_i).each do |event|
            p(event)
            update_subscriptions(event) if (channel == event.channel)
          end
        end
        add_socket(ws, channel)
      else
        add_socket(ws, channel)
        swap_sockets(subscriptions[channel].ws, ws, channel)
        subscriptions[channel] = Subscription.new(ws, channels)
        cleanup_sockets
      end
    end
  end

  def add_socket(ws, channel)
    if (@sockets[ws] == nil)
      @sockets[ws] = [channel]
    else
      @sockets[ws].push(channel)
    end
  end

  def swap_sockets(oldws, newws, channel)
    @sockets[oldws].delete(channel)
    @sockets[newws].push(channel)
  end

  def update_subscriptions(event)
    subscription = subscriptions[event.channel]
    if subscription
      ws = subscription.ws
      ws.send(event.to_json)
      jobs[event.id] = Job.new(event.id, "sent", Time.now, ws)
      process_timeout(event.id)
    end
  end

  def process_timeout(event_id)
    Thread.new do
      sleep(5)
      if (jobs[event_id].status == "sent")
        job = jobs[event_id]
        job.status = "timeout"
        job.ws = nil
        p("timeout #{event_id}")
      end
      cleanup_sockets
    end
  end

  def job_succeeded(event_id)
    job = jobs[event_id]
    job.status = "success"
    job.ws = nil
    cleanup_sockets
    p("success #{event_id}")
  end

  def job_failed(event_id)
    job = jobs[event_id]
    job.status = "error"
    job.ws = nil
    cleanup_sockets
    p("error #{event_id}")
  end

  def cleanup_sockets
    @sockets.each do |ws, channels|
      if (channels.length == 0)
        if (jobs.values.select { |job| (job.status == "sent") and (job.ws == ws) }.length == 0)
          ws.close
          @sockets.delete(ws)
        end
      end
    end
  end
end
