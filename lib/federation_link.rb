# encoding: utf-8

require 'json'

# Represents an exchange federation link
# able to generate a rabbitmqctl command to establish the link
class FederationLink
  @all_links = []
  class << self
    attr_accessor :all_links
  end

  DEFAULT_CONFIG = {
    expires: 360000
  }
  DEFAULT_POLICY = {
    'federation-upstream-set' => 'all'
  }

  def initialize(downstream, upstream_name, exchange_pattern, in_config, policy = DEFAULT_POLICY)
    @downstream = downstream
    @upstream_name = upstream_name
    @exchange_pattern = exchange_pattern
    @config = DEFAULT_CONFIG.merge(in_config)
    @policy = policy
    self.class.all_links << self
  end

  def to_cmd
    "rabbitmqctl -n #{@downstream} set_parameter federation-upstream " +
      "#{@upstream_name} '#{@config.to_json}'"
  end

  def to_policy
    "rabbitmqctl -n #{@downstream} set_policy --apply-to exchanges federate-me \"#{@exchange_pattern}\" '#{@policy.to_json}'"
  end
end
