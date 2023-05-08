# frozen_string_literal: true

module RemoteDevelopment
  module AgentConfig
    class UpdateProcessor
      def process(agent:, config:)
        config_from_agent_config_file = config[:remote_development]

        return [nil, nil] unless config_from_agent_config_file

        model_instance = RemoteDevelopmentAgentConfig.find_or_initialize_by(agent: agent) # rubocop:disable CodeReuse/ActiveRecord
        model_instance.enabled = config_from_agent_config_file[:enabled]
        # noinspection RubyResolve
        model_instance.dns_zone = config_from_agent_config_file[:dns_zone]

        if model_instance.save
          payload = { remote_development_agent_config: model_instance }
          [payload, nil]
        else
          err_msg = "Error(s) updating RemoteDevelopmentAgentConfig: #{model_instance.errors.full_messages.join(', ')}"
          error = Error.new(message: err_msg, reason: :bad_request)
          [nil, error]
        end
      end
    end
  end
end
