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

  def self.add(downstream, upstream, exchange_pattern, config)
    if @all_links[downstream.name]
      @all_links[downstream.name].add_upstream(upstream, config)
    else
      @all_links[downstream.name] = new(downstream, upstream,
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

  def initialize(downstream, upstream, exchange_pattern, in_config)
    @downstream = downstream
    @exchange_pattern = exchange_pattern
    @upstreams = {}
    add_upstream(upstream, in_config)
  end

  def add_upstream(upstream, config)
    @upstreams[upstream] = DEFAULT_CONFIG.merge(config)
  end

  def to_cmd
    upstream_set = @upstreams.keys.map do |upstream|
      { upstream: upstream.name }
    end
    [
     @upstreams.each_pair.map do |upstream, config|
       "rabbitmqctl -n #{@downstream.to_ctl} set_parameter " +
         "federation-upstream #{upstream.name} '#{config.merge(uri: upstream.uri).to_json}'"
     end,
     "rabbitmqctl -n #{@downstream.to_ctl} set_parameter federation-upstream-set " +
       "#{@downstream.name}_federators '#{upstream_set.to_json}'"
    ].flatten.join("\n")
  end

  def to_policy
    policy = { 'federation-upstream-set' => "#{@downstream.name}_federators" }
    "rabbitmqctl -n #{@downstream.to_ctl} set_policy --apply-to exchanges federate-me \"#{@exchange_pattern}\" '#{policy.to_json}'"
  end
end
