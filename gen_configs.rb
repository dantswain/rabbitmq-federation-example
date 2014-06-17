# encoding: utf-8

require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'node_template'
require 'federation_link'

HOST = `hostname -s`.chomp

[
 {
   node_dir: 'node1',
   node_name: 'node1',
   main_port: 5000,
   mgmt_port: 3000
 },
 {
   node_dir: 'node2',
   node_name: 'node2',
   main_port: 5001,
   mgmt_port: 3001
 }
].each { |node| NodeTemplate.add(node) }

FederationLink.add("node1@#{HOST}",
                   'node2',
                   'federated_*',
                   { uri: 'amqp://guest:guest@localhost:5001' })
FederationLink.add("node2@#{HOST}",
                   'node1',
                   'federated_*',
                   { uri: 'amqp://guest:guest@localhost:5000' })

NodeTemplate.render_all
NodeTemplate.write_bins
FederationLink.write_bins
