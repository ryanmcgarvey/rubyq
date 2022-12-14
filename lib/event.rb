class Event
  attr_accessor(:channel, :data, :id)

  def initialize(channel, data)
    @channel = channel
    @data = data
  end

  def as_json
    { "channel" => channel, "data" => data, "id" => id }
  end

  def to_json
    as_json.to_json
  end
end

class EventLog
  def initialize
    @events = []
  end

  def from(cursor)
    return [] if (cursor == nil)
    @events[(cursor..-1)]
  end

  def add(event)
    event.id = @events.length
    @events.push(event)
  end

  def get
    @events
  end
end
