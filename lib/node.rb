# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'erb'
require 'fileutils'
require 'federation_link'

# Represents the configuration of a local node
# generates a directory, config files, and start script for the node
class Node
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
    @all_nodes[node.name] = node
  end

  def self.render_all
    @all_nodes.each_value { |node| node.render }
  end

  def self.write_bins
    start_all = File.join(BIN_DIR, 'start_all')
    stop_all = File.join(BIN_DIR, 'stop_all')
    clean_all = File.join(BIN_DIR, 'clean_all')
    # this file gets populated by FederationLink;
    # we just need the path of it here
    setup_feds = FederationLink.setup_feds
    # similar for Shovel
    setup_shovels = Shovel.setup_shovels

    generated_files = [start_all, stop_all, clean_all, setup_feds, setup_shovels] +
      all_nodes.each_value.map { |n| "start_#{n.name}" }

    File.open(start_all, 'w') do |f|
      f.puts(all_nodes.each_value.map do |node|
               "./start_#{node.name}"
             end.join("\n"))
    end

    File.open(stop_all, 'w') do |f|
      f.puts(all_nodes.each_value.map do |node|
               "rabbitmqctl -n #{node.name}@#{HOST} stop"
             end.join("\n"))
    end

    File.open(clean_all, 'w') do |f|
      f.puts 'rm -rf ' +
        all_nodes.each_value.map { |n| n.name }.join(' ')
      generated_files.each do |g|
        f.puts "rm -f #{g}"
      end
    end

    generated_files.each { |p| FileUtils.chmod('u+x', p) if File.exist?(p) }
  end

  attr_accessor :node_dir, :name
  attr_accessor :port, :mgmt_port
  attr_accessor :host, :user, :password

  def initialize(args)
    # default values
    @user = 'guest'
    @password = 'guest'
    @host = `hostname -s`.chomp

    # explode args to instance vars
    args.each_pair do |var, val|
      instance_variable_set("@#{var}", val)
    end
  end

  def uri
    "amqp://#{user}:#{password}@#{host}:#{port}"
  end

  def to_ctl
    "#{name}@#{host}"
  end

  def render
    node_starter = "start_#{@name}"
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
