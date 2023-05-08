# frozen_string_literal: true

module RemoteDevelopment
  # This exception indicates that the agent_info fixture STATUS_YAML
  # generated by remote_development_shared_contexts.rb#create_workspace_agent_info for the given
  # state transition has not yet been correctly implemented.
  AgentInfoStatusFixtureNotImplementedError = Class.new(RuntimeError)
end
