require_relative("lib/client")
client = Client.new
client.on("success") do |data|
  p("success: #{data["id"]}")
  true
end
client.on("should_error") do |data|
  p("erroring: #{data["id"]}")
  false
end
client.on("should_timeout") do |data|
  p("timing out: #{data["id"]}")
  sleep(10)
  true
end
client.listen
