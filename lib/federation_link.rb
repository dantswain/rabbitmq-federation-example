# encoding: utf-8

require 'json'
require 'fileutils'

# Represents an exchange federation link
# able to generate a rabbitmqctl command to establish the link
class FederationLink
  @all_links = {}
  class << self
    attr_accessor :all_links
  end

  BIN_DIR = File.expand_path('../..', __FILE__)
  DEFAULT_CONFIG = {
    expires: 360000
  }

  def self.add(downstream, host, upstream_name, exchange_pattern, config)
    if @all_links[downstream]
      @all_links[downstream].add_upstream(upstream_name, config)
    else
      @all_links[downstream] = new(downstream, host, upstream_name,
                                   exchange_pattern, config)
    end
  end

  def self.setup_feds
    File.join(BIN_DIR, 'setup_feds')
  end

  def self.write_bins
    File.open(setup_feds, 'w') do |f|
      FederationLink.all_links.values.each do |link|
        f.puts link.to_cmd
        f.puts link.to_policy
      end
    end
    FileUtils.chmod('u+x', setup_feds)
  end

  def initialize(downstream, downstream_host, upstream_name, exchange_pattern, in_config)
    @downstream = downstream
    @downstream_host = downstream_host
    @upstreams = { upstream_name => DEFAULT_CONFIG.merge(in_config) }
    @exchange_pattern = exchange_pattern
    @upstreams = {}
    add_upstream(upstream_name, in_config)
  end

  def add_upstream(upstream_name, config)
    @upstreams[upstream_name] = DEFAULT_CONFIG.merge(config)
  end

  def node_connection
    @downstream + '@' + @downstream_host
  end

  def to_cmd
    upstream_set = @upstreams.keys.map do |name|
      { upstream: name }
    end
    [
     @upstreams.each_pair.map do |name, config|
       "rabbitmqctl -n #{node_connection} set_parameter " +
         "federation-upstream #{name} '#{config.to_json}'"
     end,
     "rabbitmqctl -n #{node_connection} set_parameter federation-upstream-set " +
     "#{@downstream}_federators '#{upstream_set.to_json}'"
    ].flatten.join("\n")
  end

  def to_policy
    policy = { 'federation-upstream-set' => "#{@downstream}_federators" }
    "rabbitmqctl -n #{node_connection} set_policy --apply-to exchanges federate-me \"#{@exchange_pattern}\" '#{policy.to_json}'"
  end
end
