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

# publish a message on node 2
puts 'PUBLISHING'
from_node = 1
nodes[from_node].channel.topic('federated_1').publish("hi test from node #{from_node}", routing_key: 'test.foo')

q5.subscribe(block: true) do |di, m, p|
  puts "GOT #{p.inspect}"
  di.consumer.cancel
end

puts 'DONE'
