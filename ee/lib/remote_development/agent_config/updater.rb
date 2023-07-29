# frozen_string_literal: true

module RemoteDevelopment
  module AgentConfig
    class Updater
      include Messages

      # @param [Hash] value
      # @return [Result]
      def self.update(value)
        value => { agent: Clusters::Agent => agent, config: Hash => config }
        config_from_agent_config_file = config[:remote_development]

        unless config_from_agent_config_file
          return Result.ok(
            AgentConfigUpdateSkippedBecauseNoConfigFileEntryFound.new({ skipped_reason: :no_config_file_entry_found })
          )
        end

        model_instance = RemoteDevelopmentAgentConfig.find_or_initialize_by(agent: agent) # rubocop:disable CodeReuse/ActiveRecord
        model_instance.enabled = config_from_agent_config_file[:enabled]
        # noinspection RubyResolve
        model_instance.dns_zone = config_from_agent_config_file[:dns_zone]
        # noinspection RubyResolve
        model_instance.network_policy_enabled =
          config_from_agent_config_file.fetch(:network_policy, {}).fetch(:enabled, true)
        # noinspection RubyResolve
        model_instance.gitlab_workspaces_proxy_namespace =
          config_from_agent_config_file.fetch(:gitlab_workspaces_proxy, {}).fetch(:namespace, 'gitlab-workspaces')

        # NOTE: Currently, this will always be expected to fail if the config's `enabled: false` is
        #       specified, because for the initial release, we are enforcing that all config attributes (including
        #       `enabled`) are immutable, and thus enabled must be set to true upon creation.
        if model_instance.save
          Result.ok(AgentConfigUpdateSuccessful.new({ remote_development_agent_config: model_instance }))
        else
          Result.err(AgentConfigUpdateFailed.new({ errors: model_instance.errors }))
        end
      end
    end
  end
end
