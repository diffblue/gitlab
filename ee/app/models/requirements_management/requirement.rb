# frozen_string_literal: true

module RequirementsManagement
  class Requirement < ApplicationRecord
    include CacheMarkdownField
    include StripAttribute
    include AtomicInternalId
    include Sortable
    include Gitlab::SQL::Pattern

    # the expected name for this table is `requirements_management_requirements`,
    # but to avoid downtime and deployment issues `requirements` is still used
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30052#note_329556542
    self.table_name = 'requirements'
    STATE_MAP = { opened: 'opened', closed: 'archived' }.with_indifferent_access.freeze

    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description, issuable_reference_expansion_enabled: true

    strip_attributes! :title

    belongs_to :author, inverse_of: :requirements, class_name: 'User'
    belongs_to :project, inverse_of: :requirements
    # deleting an issue would result in deleting requirement record due to cascade delete via foreign key
    # but to sync the other way around, we require a temporary `dependent: :destroy`
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/323779 for details.
    # This will be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/329432
    belongs_to :requirement_issue, class_name: 'Issue', foreign_key: :issue_id, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    validates :project, presence: true
    validates :requirement_issue, presence: true, on: [:create, :update]

    validates :issue_id, uniqueness: true

    has_many :test_reports, through: :requirement_issue
    has_many :recent_test_reports, -> { order('requirements_management_test_reports.created_at DESC') }, through: :requirement_issue, source: :test_reports
    has_internal_id :iid, scope: :project

    validate :only_requirement_type_issue

    after_validation :invalidate_if_sync_error, on: [:update, :create]

    delegate :title,
             :author,
             :author_id,
             :description,
             :description_html,
             :title_html,
             :cached_markdown_version,
             :created_at,
             :updated_at,
             to: :requirement_issue,
             allow_nil: true

    enum state: { opened: 1, archived: 2 }

    scope :with_issue, -> { joins(:requirement_issue) }
    scope :for_iid, -> (iid) { where(iid: iid) }
    scope :with_author, -> (user) { with_issue.where('issues.author': user) }

    # overrides default sortable scopes
    scope :order_created_desc, -> { with_issue.reorder('issues.created_at desc') }
    scope :order_created_asc, -> { with_issue.reorder('issues.created_at asc') }
    scope :order_updated_desc, -> { with_issue.reorder('issues.updated_at desc') }
    scope :order_updated_asc, -> { with_issue.reorder('issues.updated_at asc') }

    scope :for_state, -> (state) { with_issue.where('issues.state_id': to_issue_state_id(state)) }

    scope :counts_by_state, -> do
      counts = with_issue.group('issues.state_id').count

      counts.transform_keys do |state_id|
        state_name = Issue.available_states.key(state_id)
        STATE_MAP[state_name]
      end
    end

    # Used to filter requirements by latest test report state
    scope :include_last_test_report_with_state, -> do
      joins(
        "INNER JOIN LATERAL (
           SELECT DISTINCT ON (issue_id) issue_id, state
           FROM requirements_management_test_reports
           WHERE issue_id = requirements.issue_id
           ORDER BY issue_id, created_at DESC LIMIT 1
        ) AS test_reports ON true"
      )
    end

    scope :with_last_test_report_state, -> (state) do
      include_last_test_report_with_state.where( test_reports: { state: state } )
    end

    scope :without_test_reports, -> do
      left_joins(:test_reports).where(requirements_management_test_reports: { issue_id: nil })
    end

    class << self
      # Searches for records with a matching title.
      #
      # This method uses ILIKE on PostgreSQL
      #
      # query - The search query as a String
      #
      # Returns an ActiveRecord::Relation.
      def search(query)
        with_issue.fuzzy_search(query, [Issue.arel_table[:title]])
      end

      def simple_sorts
        super.except('name_asc', 'name_desc')
      end

      def sync_params
        [:title, :description, :state, :project_id, :author_id]
      end

      def to_issue_state_id(state)
        name = STATE_MAP.invert[state.to_s]
        Issue.available_states[name]
      end
    end

    # In the next iteration we will support also group-level requirements
    # so it's better to use resource_parent instead of project directly
    def resource_parent
      project
    end

    def latest_report
      recent_test_reports.first
    end

    def last_test_report_state
      latest_report&.state
    end

    def last_test_report_manually_created?
      latest_report&.build.nil?
    end

    def only_requirement_type_issue
      errors.add(:requirement_issue, "must be a `requirement`. You cannot associate a Requirement with an issue of type #{requirement_issue.issue_type}.") if requirement_issue && !requirement_issue.requirement? && will_save_change_to_issue_id?
    end

    def requirement_issue_sync_error!(invalid_issue:)
      self.invalid_requirement_issue = invalid_issue
    end

    def state
      return unless requirement_issue&.requirement?

      STATE_MAP[requirement_issue.state]
    end

    private

    attr_accessor :invalid_requirement_issue # Used to retrieve error messages

    def invalidate_if_sync_error
      return unless invalid_requirement_issue

      # Mirror errors from requirement issue so that users can adjust accordingly
      errors = invalid_requirement_issue.errors.full_messages.to_sentence if invalid_requirement_issue

      errors = errors.presence || "Associated issue was invalid and changes could not be applied."
      self.errors.add(:base, errors)
    end
  end
end
