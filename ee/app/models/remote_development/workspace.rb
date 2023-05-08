# frozen_string_literal: true

module RemoteDevelopment
  # noinspection RailsParamDefResolve,RubyResolve
  class Workspace < ApplicationRecord
    include Sortable
    include RemoteDevelopment::Workspaces::States

    MAX_HOURS_BEFORE_TERMINATION_LIMIT = 120

    belongs_to :user, inverse_of: :workspaces
    belongs_to :project, inverse_of: :workspaces
    belongs_to :agent, class_name: 'Clusters::Agent', foreign_key: 'cluster_agent_id', inverse_of: :workspaces

    has_one :remote_development_agent_config, through: :agent, source: :remote_development_agent_config
    delegate :dns_zone, to: :remote_development_agent_config, prefix: false, allow_nil: false

    validates :user, presence: true
    validates :agent, presence: true
    validates :editor, presence: true

    # Ensure that the associated agent has an existing RemoteDevelopmentAgentConfig before we allow it
    # to be used to create a new workspace
    validate :validate_agent_config_presence

    # We do not yet support workspaces for private projects, so validate that the associated project is currently public
    validate :validate_project_is_public

    # See https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/blob/main/doc/architecture.md?plain=0#workspace-states
    # for state validation rules
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409773
    #       Add validation preventing desired_state change if it is TERMINATED; you can't restart a terminated workspace
    #       Also reflect this in GraphQL API and Vue component UI
    validates :desired_state, inclusion: { in: VALID_DESIRED_STATES }
    validates :actual_state, inclusion: { in: VALID_ACTUAL_STATES }
    validates :editor, inclusion: { in: ['webide'], message: "'webide' is currently the only supported editor" }
    validates :max_hours_before_termination, numericality: { less_than_or_equal_to: MAX_HOURS_BEFORE_TERMINATION_LIMIT }

    scope :with_desired_state_updated_more_recently_than_last_response_to_agent, -> do
      # noinspection SqlResolve
      where('desired_state_updated_at >= responded_to_agent_at').or(where(responded_to_agent_at: nil))
    end

    before_save :touch_desired_state_updated_at, if: ->(workspace) do
      workspace.new_record? || workspace.desired_state_changed?
    end

    def desired_state_updated_more_recently_than_last_response_to_agent?
      return true if responded_to_agent_at.nil?

      desired_state_updated_at >= responded_to_agent_at
    end

    def terminated?
      actual_state == TERMINATED
    end

    private

    def validate_agent_config_presence
      return true if agent.remote_development_agent_config

      errors.add(:agent, _('for Workspace must have an associated RemoteDevelopmentAgentConfig'))
    end

    def validate_project_is_public
      return true if project.public?

      errors.add(:project, _('for Workspace is required to be public'))
    end

    def touch_desired_state_updated_at
      self.desired_state_updated_at = Time.current.utc
    end
  end
end
