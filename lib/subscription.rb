class Subscription
  attr_reader(:name, :ws, :channel)

  def initialize(name, ws, channel)
    @name = name
    @ws = ws
    @channel = channel
  end
end

class SubscriptionManager
  attr_reader(:subscriptions)

  def initialize
    @subscriptions = {}
  end

  def update_subscriptions(event)
    subscriptions.each do |name, subscription|
      if (subscription.channel == event.channel)
        subscription.ws.send(event.to_json)
      end
    end
  end
end
