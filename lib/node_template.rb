# encoding: utf-8

require 'erb'
require 'fileutils'

# Represents the configuration of a local node
# generates a directory, config files, and start script for the node
class NodeTemplate
  @all_nodes = {}
  TEMPLATE_DIR = File.expand_path('../..', __FILE__)
  BIN_DIR = File.expand_path('../..', __FILE__)
  class << self
    attr_reader :all_nodes
  end

  def self.[](name)
    @all_nodes[name]
  end

  def self.add(*args)
    node = new(*args)
    @all_nodes[node.node_name] = node
  end

  def self.render_all
    @all_nodes.each_value { |node| node.render }
  end

  def self.write_bins
    start_all = File.join(BIN_DIR, 'start_all')
    File.open(start_all, 'w') do |f|
      f.puts(all_nodes.each_value.map do |node|
               "./start_#{node.node_name}"
             end.join("\n"))
    end

    stop_all = File.join(BIN_DIR, 'stop_all')
    File.open(stop_all, 'w') do |f|
      f.puts(all_nodes.each_value.map do |node|
               "rabbitmqctl -n #{node.node_name}@#{HOST} stop"
             end.join("\n"))
    end

    clean_all = File.join(BIN_DIR, 'clean_all')
    File.open(clean_all, 'w') do |f|
      f.puts 'rm -rf ' +
        NodeTemplate.all_nodes.each_value.map { |t| t.node_name }.join(' ')
    end

    [start_all, stop_all, clean_all].each { |p| FileUtils.chmod('u+x', p) }
  end

  attr_accessor :node_dir, :node_name
  attr_accessor :main_port, :mgmt_port, :upstream_port, :upstream
  attr_accessor :host

  def initialize(args)
    args.each_pair do |var, val|
      instance_variable_set("@#{var}", val)
    end
  end

  def render
    node_starter = "start_#{@node_name}"
    FileUtils.mkdir_p(@node_dir)
    File.open(File.join(@node_dir, 'rabbitmq.config'), 'w') do |f|
      f.puts ERB.new(File.read(File.join(TEMPLATE_DIR, 'rabbitmq.config.erb'))).result(binding)
    end
    File.open(File.join(node_starter), 'w') do |f|
      f.puts ERB.new(File.read(File.join(TEMPLATE_DIR, 'start_node.erb'))).result(binding)
    end
    FileUtils.chmod('u+x', node_starter)
    FileUtils.cp(File.join(TEMPLATE_DIR, 'enabled_plugins'), @node_dir)
  end
end
