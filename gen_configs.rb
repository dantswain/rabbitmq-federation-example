# encoding: utf-8

# Sets up 5 rabbitmq nodes on localhost, listening on ports
# 5001-5005, management consoles on ports 3001-3005.  Sets
# up an exchange federation policy for any exchange named
# federated_* on these nodes.  The federation topology is
# an undirected star graph with node 1 at the center.

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

# read as:
#   node 1 has nodes 2, 3, 4, 5 as upstreams
#   node 2 has node 1 as upstream
#   node 3 has node 1 as upstream
#     .. etc
topology = {
  1 => [2, 3, 4, 5],
  2 => 1,
  3 => 1,
  4 => 1,
  5 => 1
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
    from = NodeTemplate["node#{from_ix}"]
    to = NodeTemplate["node#{to_ix}"]
    FederationLink.add(from.node_name,
                       HOST,
                       to.node_name,
                       'federated_*',
                       uri: "amqp://guest:guest@localhost:#{to.main_port}",
                       'max-hops' => 2)
  end
end

NodeTemplate.render_all
NodeTemplate.write_bins
FederationLink.write_bins
