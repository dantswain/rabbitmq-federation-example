# encoding: utf-8

# Sets up 5 rabbitmq nodes on localhost, listening on ports
# 5001-5005, management consoles on ports 3001-3005.  Sets
# up an exchange federation policy for any exchange named
# federated_* on these nodes.  The federation topology is
# an undirected star graph with node 1 at the center.

require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'node'
require 'federation_link'
require 'shovel'

HOST = `hostname -s`.chomp

(1..5).each do |ix|
  Node.add(node_dir: "node#{ix}",
           name: "node#{ix}",
           port: 5000 + ix,
           mgmt_port: 3000 + ix)
end

# read as:
#   node 1 has nodes 2, 3, 4, 5 as upstreams
#   node 2 has node 1 as upstream
#   node 3 has node 1 as upstream
#     .. etc
topology = {
  1 => [2, 3, 4, 5],
  2 => [1],
  3 => [1],
  4 => [1],
  5 => [1]
}

# another example - a directed ring graph
# topology = {
#   1 => 2,
#   2 => 3,
#   3 => 4,
#   4 => 5,
#   5 => 1}
#   Would need to set max-hops to 4

topology.each_pair do |from_ix, to_ixs|
  [to_ixs].flatten.each do |to_ix|
    from = Node["node#{from_ix}"]
    to = Node["node#{to_ix}"]
    FederationLink.add(from,
                       to,
                       'federated_*',
                       'max-hops' => 2)
  end
end

(1..3).each do |ix|
  Shovel.add("test_shovel_#{ix}", Node["node#{ix}"],
             {
               'src-uri' => 'amqp://guest:guest@localhost:5001',
               'src-exchange' => 'shovel_test_source',
               'src-exchange-key' => '*',
               'dest-uri' => "amqp://guest:guest@localhost:500#{ix}",
               'dest-exchange' => 'shovel_test_dest',
             })
    .command(3000 + ix, 'declare exchange name=shovel_test_dest type=topic')
    .command(3000 + ix, 'declare queue name=shovel_listener durable=true')
    .command(3000 + ix, 'declare binding source="shovel_test_dest" destination="shovel_listener" routing_key="*"')
end
Shovel["test_shovel_1"].command(3001, "declare exchange name=shovel_test_source type=topic")

Node.render_all
Node.write_bins
FederationLink.write_bins
Shovel.write_bins
