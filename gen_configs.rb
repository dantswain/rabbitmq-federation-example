# encoding: utf-8

require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'node_template'
require 'federation_link'

HOST = `hostname -s`.chomp

node1 = NodeTemplate.new(node_dir: 'node1',
                         node_name: 'node1',
                         main_port: 5000,
                         mgmt_port: 3000)

node2 = NodeTemplate.new(node_dir: 'node2',
                         node_name: 'node2',
                         main_port: 5001,
                         mgmt_port: 3001)

node1_node2 = FederationLink.new("node1@#{HOST}",
                                 'node2',
                                 { uri: 'amqp://guest:guest@localhost:5001' })

[node1, node2].each { |c| c.render }

File.open('setup_feds', 'w') do |f|
  f.puts node1_node2.to_cmd
end

FileUtils.chmod('u+x', 'setup_feds')
