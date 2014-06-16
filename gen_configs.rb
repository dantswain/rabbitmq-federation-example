# encoding: utf-8

require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'node_template'
require 'federation_link'

HOST = `hostname -s`.chomp

NodeTemplate.new(node_dir: 'node1',
                 node_name: 'node1',
                 main_port: 5000,
                 mgmt_port: 3000)

NodeTemplate.new(node_dir: 'node2',
                 node_name: 'node2',
                 main_port: 5001,
                 mgmt_port: 3001)

FederationLink.new("node1@#{HOST}",
                   'node2',
                   'federated_*',
                   { uri: 'amqp://guest:guest@localhost:5001' })
FederationLink.new("node2@#{HOST}",
                   'node1',
                   'federated_*',
                   { uri: 'amqp://guest:guest@localhost:5000' })

NodeTemplate.all_nodes.each { |node| node.render }

File.open('setup_feds', 'w') do |f|
  FederationLink.all_links.each do |link| 
    f.puts link.to_cmd
    f.puts link.to_policy
  end
end

FileUtils.chmod('u+x', 'setup_feds')

File.open('start_all', 'w') do |f|
  f.puts(NodeTemplate.all_nodes.map do |node|
    "./start_#{node.node_name}"
  end.join("\n"))
end
FileUtils.chmod('u+x', 'start_all')

File.open('stop_all', 'w') do |f|
  f.puts(NodeTemplate.all_nodes.map do |node|
    "rabbitmqctl -n #{node.node_name}@#{HOST} stop"
  end.join("\n"))
end
FileUtils.chmod('u+x', 'stop_all')

File.open('clean_all', 'w') do |f|
  f.puts 'rm -rf ' + NodeTemplate.all_nodes.map { |t| t.node_name }.join(' ')
end
FileUtils.chmod('u+x', 'clean_all')
