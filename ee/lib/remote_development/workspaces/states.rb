# frozen_string_literal: true

# See: https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/blob/main/doc/architecture.md?plain=0#workspace-states
module RemoteDevelopment
  module Workspaces
    module States
      CREATION_REQUESTED = 'CreationRequested'
      STARTING = 'Starting'
      RESTART_REQUESTED = 'RestartRequested'
      RUNNING = 'Running'
      STOPPING = 'Stopping'
      STOPPED = 'Stopped'
      TERMINATING = 'Terminating'
      TERMINATED = 'Terminated'
      FAILED = 'Failed'
      ERROR = 'Error'
      UNKNOWN = 'Unknown'

      VALID_DESIRED_STATES = [
        RUNNING,
        RESTART_REQUESTED,
        STOPPED,
        TERMINATED
      ].freeze

      VALID_ACTUAL_STATES = [
        CREATION_REQUESTED, # Default initial actual_state for new workspace until we first receive it back from agentk
        STARTING,
        RUNNING,
        STOPPING,
        STOPPED,
        TERMINATING,
        TERMINATED,
        FAILED,
        ERROR,
        UNKNOWN # NOTE: This is used if agentk couldn't determine the state, e.g. if informer does not provide the phase
      ].freeze

      def valid_desired_state?(string)
        VALID_DESIRED_STATES.include?(string)
      end

      def valid_actual_state?(string)
        VALID_ACTUAL_STATES.include?(string)
      end
    end
  end
end
