# frozen_string_literal: true

module EE
  module Board
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    # Empty state for milestones and weights.
    EMPTY_SCOPE_STATE = [nil, -1].freeze

    prepended do
      belongs_to :milestone
      belongs_to :iteration
      belongs_to :iteration_cadence, class_name: 'Iterations::Cadence'

      has_many :board_labels
      has_many :user_preferences, class_name: 'BoardUserPreference', inverse_of: :board
      has_many :boards_epic_user_preferences, class_name: 'Boards::EpicUserPreference', inverse_of: :board

      # These can safely be changed to has_many when we support
      # multiple assignees on the board configuration.
      # https://gitlab.com/gitlab-org/gitlab/issues/3786
      has_one :board_assignee
      has_one :assignee, through: :board_assignee

      has_many :labels, through: :board_labels

      scope :with_associations, -> { preload(:destroyable_lists, :labels, :assignee) }
      scope :in_iterations, ->(iterations) { where(iteration: iterations) }
      scope :in_iteration_cadences, ->(cadences) { where(iteration_cadence: cadences) }
    end

    override :scoped?
    def scoped?
      return super unless resource_parent.feature_available?(:scoped_issue_board)

      EMPTY_SCOPE_STATE.exclude?(milestone_id) ||
        EMPTY_SCOPE_STATE.exclude?(weight) ||
        labels.any? ||
        assignee.present?
    end

    def milestone
      return unless resource_parent&.feature_available?(:scoped_issue_board)

      case milestone_id
      when ::Milestone::None.id
        ::Milestone::None
      when ::Milestone::Any.id
        ::Milestone::Any
      when ::Milestone::Upcoming.id
        ::Milestone::Upcoming
      when ::Milestone::Started.id
        ::Milestone::Started
      else
        super
      end
    end

    def iteration
      return unless resource_parent&.feature_available?(:scoped_issue_board)

      case iteration_id
      when ::Iteration::Predefined::None.id
        ::Iteration::Predefined::None
      when ::Iteration::Predefined::Any.id
        ::Iteration::Predefined::Any
      when ::Iteration::Predefined::Current.id
        ::Iteration::Predefined::Current
      else
        super
      end
    end
  end
end
