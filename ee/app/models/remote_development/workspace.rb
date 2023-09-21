# frozen_string_literal: true

module RemoteDevelopment
  # noinspection RailsParamDefResolve, RubyResolve - likely due to https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31540
  # noinspection RubyConstantNamingConvention,RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  class Workspace < ApplicationRecord
    include Sortable
    include RemoteDevelopment::Workspaces::States
    include IgnorableColumns

    MAX_HOURS_BEFORE_TERMINATION_LIMIT = 120

    belongs_to :user, inverse_of: :workspaces
    belongs_to :project, inverse_of: :workspaces
    belongs_to :agent, class_name: 'Clusters::Agent', foreign_key: 'cluster_agent_id', inverse_of: :workspaces
    belongs_to :personal_access_token, inverse_of: :workspace

    has_one :remote_development_agent_config, through: :agent, source: :remote_development_agent_config
    has_many :workspace_variables, class_name: 'RemoteDevelopment::WorkspaceVariable', inverse_of: :workspace

    delegate :dns_zone, to: :remote_development_agent_config, prefix: false, allow_nil: false

    validates :user, presence: true
    validates :agent, presence: true
    validates :editor, presence: true

    # Ensure that the associated agent has an existing RemoteDevelopmentAgentConfig before we allow it
    # to be used to create a new workspace
    validate :validate_agent_config_presence

    # See https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/blob/main/doc/architecture.md?plain=0#workspace-states
    # for state validation rules
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409773
    #       Add validation preventing desired_state change if it is TERMINATED; you can't restart a terminated workspace
    #       Also reflect this in GraphQL API and Vue component UI
    validates :desired_state, inclusion: { in: VALID_DESIRED_STATES }
    validates :actual_state, inclusion: { in: VALID_ACTUAL_STATES }
    validates :editor, inclusion: { in: ['webide'], message: "'webide' is currently the only supported editor" }
    validates :max_hours_before_termination, numericality: { less_than_or_equal_to: MAX_HOURS_BEFORE_TERMINATION_LIMIT }

    ignore_column :force_full_reconciliation, remove_with: '16.7', remove_after: '2023-11-22'

    scope :with_desired_state_updated_more_recently_than_last_response_to_agent, -> do
      # noinspection SqlResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
      where('desired_state_updated_at >= responded_to_agent_at').or(where(responded_to_agent_at: nil))
    end

    scope :by_project_ids, ->(ids) { where(project_id: ids) }
    scope :with_actual_states, ->(actual_states) { where(actual_state: actual_states) }
    scope :without_terminated, -> do
      where.not(
        desired_state: RemoteDevelopment::Workspaces::States::TERMINATED,
        actual_state: RemoteDevelopment::Workspaces::States::TERMINATED
      )
    end

    scope :ordered_by_id, -> { order(:id) }

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
      # NOTE: The `agent&.` safe navigation operator is necessary in order for the `belong_to(:agent)` association
      #       specs to work. It's fine, because we separately validate the presence of agent, and adding the missing
      #       config validation additionally is technically accurate, because it's true there's not a config.
      return true if agent&.remote_development_agent_config

      errors.add(:agent, _('for Workspace must have an associated RemoteDevelopmentAgentConfig'))
    end

    def touch_desired_state_updated_at
      self.desired_state_updated_at = Time.current.utc
    end
  end
end
