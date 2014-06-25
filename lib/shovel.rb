# encoding: utf-8

require 'json'
require 'fileutils'

# Represents a shovel link
class Shovel
  @all_shovels = {}
  class << self
    attr_accessor :all_shovels
  end

  BIN_DIR = File.expand_path('../..', __FILE__)

  def self.add(name, on_node, config)
    @all_shovels[name] = new(name, on_node, config)
  end

  def self.setup_shovels
    File.join(BIN_DIR, 'setup_shovels')
  end

  def self.write_bins
    File.open(setup_shovels, 'w') do |f|
      all_shovels.values.each do |shovel|
        f.puts shovel.to_cmd
      end
    end
    FileUtils.chmod('u+x', setup_shovels)
  end

  def self.[](name)
    @all_shovels[name]
  end

  attr_accessor :name, :on_node, :config, :commands

  def initialize(name, on_node, config)
    @name = name
    @on_node = on_node
    @config = config
    @commands = []
  end

  def command(mgmt_port, command)
    @commands << "rabbitmqadmin -P #{mgmt_port} #{command}"
    self  # return self for chaining
  end

  def to_cmd
    # note management commands should come first since we might
    # need to ensure that an exchange exists
    [
     @commands,
     "rabbitmqctl -n #{@on_node.to_ctl} set_parameter shovel #{@name} '#{@config.to_json}'"
    ].flatten.join("\n")
  end
end
