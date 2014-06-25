# encoding: utf-8

# gem install bunny
require 'bunny'

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

puts 'PUBLISHING'
x = nodes[1].channel.topic('shovel_test_source', durable: true)
x.publish('HI from node 1', routing_key: 'test')

(1..3).each do |ix|
  q = nodes[ix].channel.queue('shovel_listener', durable: true)
  loop do
    _di, _m, p = q.get
    break unless p
    puts "GOT '#{p.inspect}' on #{ix}"
  end
end
