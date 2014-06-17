# encoding: utf-8

require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'node_template'
require 'federation_link'

HOST = `hostname -s`.chomp

(1..5).each do |ix|
  NodeTemplate.add(node_dir: "node#{ix}",
                   node_name: "node#{ix}",
                   main_port: 5000 + ix,
                   mgmt_port: 3000 + ix)
end

{
  1 => 2,
  2 => 3,
  3 => 4,
  4 => 5,
  5 => 1
}.each_pair do |from_ix, to_ix|
  from = NodeTemplate["node#{from_ix}"]
  to = NodeTemplate["node#{to_ix}"]
  FederationLink.add("#{from.node_name}@#{HOST}",
                     to.node_name,
                     'federated_*',
                     { uri: "amqp://guest:guest@localhost:#{to.main_port}" })
end

NodeTemplate.render_all
NodeTemplate.write_bins
FederationLink.write_bins
