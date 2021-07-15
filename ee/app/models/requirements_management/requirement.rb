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

    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description, issuable_state_filter_enabled: true

    strip_attributes :title

    belongs_to :author, inverse_of: :requirements, class_name: 'User'
    belongs_to :project, inverse_of: :requirements
    # deleting an issue would result in deleting requirement record due to cascade delete via foreign key
    # but to sync the other way around, we require a temporary `dependent: :destroy`
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/323779 for details.
    # This will be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/329432
    belongs_to :requirement_issue, class_name: 'Issue', foreign_key: :issue_id, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    validates :issue_id, uniqueness: true, allow_nil: true

    has_many :test_reports, inverse_of: :requirement
    has_many :recent_test_reports, -> { order(created_at: :desc) }, class_name: 'TestReport', inverse_of: :requirement

    has_internal_id :iid, scope: :project

    validates :author, :project, :title, presence: true

    validates :title, length: { maximum: Issuable::TITLE_LENGTH_MAX }
    validates :title_html, length: { maximum: Issuable::TITLE_HTML_LENGTH_MAX }, allow_blank: true

    validate :only_requirement_type_issue

    enum state: { opened: 1, archived: 2 }

    scope :for_iid, -> (iid) { where(iid: iid) }
    scope :for_state, -> (state) { where(state: state) }
    scope :with_author, -> (user) { where(author: user) }
    scope :counts_by_state, -> { group(:state).count }

    # Used to filter requirements by latest test report state
    scope :include_last_test_report_with_state, -> do
      joins(
        "INNER JOIN LATERAL (
           SELECT DISTINCT ON (requirement_id) requirement_id, state
           FROM requirements_management_test_reports
           WHERE requirement_id = requirements.id
           ORDER BY requirement_id, created_at DESC LIMIT 1
        ) AS test_reports ON true"
      )
    end

    scope :with_last_test_report_state, -> (state) do
      include_last_test_report_with_state.where( test_reports: { state: state } )
    end

    scope :without_test_reports, -> do
      left_joins(:test_reports).where(requirements_management_test_reports: { requirement_id: nil })
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
        fuzzy_search(query, [:title])
      end

      def simple_sorts
        super.except('name_asc', 'name_desc')
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
  end
end
