# encoding: utf-8

require 'json'

# Represents an exchange federation link
# able to generate a rabbitmqctl command to establish the link
class FederationLink
  DEFAULT_CONFIG = {
    expires: 360000
  }

  def initialize(downstream, upstream_name, in_config)
    @downstream = downstream
    @upstream_name = upstream_name
    @config = DEFAULT_CONFIG.merge(in_config)
  end

  def to_cmd
    "rabbitmqctl -n #{@downstream} set_parameter federation-upstream " +
      "#{@upstream_name} '#{@config.to_json}'"
  end
end
