# encoding: utf-8

# gem install bunny
require 'bunny'

# assumes you've generated a ring topology on ports 5001-5005

class BunnyWrapper
  attr_accessor :bunny, :channel
  def initialize(uri)
    @bunny = Bunny.new(uri)
    @bunny.start
    @channel = @bunny.create_channel
  end
end

nodes = {}
(1..5).each do |ix|
  nodes[ix] = BunnyWrapper.new("amqp://guest:guest@localhost:#{5000 + ix}")
end

# creating one exchange should lead to all nodes having the same exchange
nodes[1].channel.topic('federated_1')

# create a listener queue on node 5
t5 = nodes[5].channel.topic('federated_1')
q5 = nodes[5].channel.queue('node5_fed_listener', durable: true)
q5.bind(t5, routing_key: 'test.*')
t2 = nodes[2].channel.topic('federated_1')
q2 = nodes[2].channel.queue('node2_fed_listener', durable: true)
q2.bind(t2, routing_key: 'test.*')

# publish a message on node 2
puts 'PUBLISHING'
(1..5).each do |from_node|
  x = nodes[from_node].channel.topic('federated_1')
  x.on_return do |info, prop, payload|
    puts "UH OH #{info.inspect}, #{prop.inspect}, #{payload.inspect}"
  end
  x.publish("hi test from node #{from_node}", routing_key: 'test.foo')
end

puts 'WAITING'
sleep(0.5)
loop do
  _di, _m, p = q5.get
  break unless p
  puts "GOT (node 5) #{p.inspect}"
end

loop do
  _di, _m, p = q2.get
  break unless p
  puts "GOT (node 2) #{p.inspect}"
end

puts 'DONE'
