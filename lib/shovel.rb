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

  attr_accessor :name, :on_node, :config

  def initialize(name, on_node, config)
    @name = name
    @on_node = on_node
    @config = config
  end

  def to_cmd
    "rabbitmqctl -n #{@on_node} set_parameter shovel #{@name} '#{@config.to_json}'"
  end
end
