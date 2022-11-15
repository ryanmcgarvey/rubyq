class Event
  attr_accessor(:channel, :data, :id)

  def initialize(channel, data)
    @channel = channel
    @data = data
  end

  def to_json
    { "channel" => channel, "data" => data, "id" => id }.to_json
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
