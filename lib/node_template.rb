# encoding: utf-8

require 'erb'
require 'fileutils'

# Represents the configuration of a local node
# generates a directory, config files, and start script for the node
class NodeTemplate
  @all_nodes = []
  TEMPLATE_DIR = File.expand_path('../..', __FILE__)
  class << self
    attr_reader :all_nodes
  end

  attr_accessor :node_dir, :node_name
  attr_accessor :main_port, :mgmt_port, :upstream_port, :upstream
  attr_accessor :host

  def initialize(args)
    args.each_pair do |var, val|
      instance_variable_set("@#{var}", val)
    end
    self.class.all_nodes << self
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
