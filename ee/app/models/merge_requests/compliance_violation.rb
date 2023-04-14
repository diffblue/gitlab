# frozen_string_literal: true

module MergeRequests
  class ComplianceViolation < ApplicationRecord
    include BulkInsertSafe
    include EachBatch
    include FromUnion

    self.table_name = 'merge_requests_compliance_violations'

    enum reason: ::Enums::MergeRequests::ComplianceViolation.reasons
    enum severity_level: ::Enums::MergeRequests::ComplianceViolation.severity_levels

    scope :with_violating_user, -> { preload(:violating_user) }
    scope :with_merge_requests, -> { preload(merge_request: [{ target_project: :namespace }, :metrics]) }
    scope :join_merge_requests, -> { with_merge_requests.joins(:merge_request) }
    scope :join_projects, -> { with_merge_requests.joins(merge_request: { target_project: :namespace }) }
    scope :join_metrics, -> { with_merge_requests.joins(merge_request: :metrics) }

    scope :by_approved_by_committer, -> { where(reason: ::Gitlab::ComplianceManagement::Violations::ApprovedByCommitter::REASON) }
    scope :by_group, -> (group) { join_projects.where(merge_requests: { projects: { namespace_id: group.self_and_descendants } }) }
    scope :by_projects, -> (project_ids) { join_merge_requests.where(merge_requests: { target_project_id: project_ids }) }
    scope :merged_before, -> (date) { where("merged_at <= ?", date.end_of_day) }
    scope :merged_after, -> (date) { where("merged_at >= ?", date.beginning_of_day) }
    scope :by_target_branch, -> (branch) { where(target_branch: branch) }
    scope :order_by_reason, -> (direction) { order(reason: direction, id: direction) }
    scope :order_by_severity_level, -> (direction) { order(severity_level: direction, id: direction) }
    scope :order_by_merge_request_title, -> (direction) { join_merge_requests.order("\"merge_requests\".\"title\" #{direction.to_s.upcase}", id: direction).references(:merge_request) }
    scope :order_by_merged_at, -> (direction) { join_metrics.order("\"merge_request_metrics\".\"merged_at\" #{direction.to_s.upcase}", id: direction).references(:merge_request_metrics) }

    scope :in_optimization_array_mapping_scope, -> (id_expression) { where(arel_table[:target_project_id].eq(id_expression)) }
    scope :in_optimization_finder_query, -> (_, id_expression) { where(arel_table[:id].eq(id_expression)) }

    belongs_to :violating_user, class_name: 'User'
    belongs_to :merge_request

    validates :violating_user, presence: true
    validates :merge_request,
              presence: true,
              uniqueness: {
                scope: [:violating_user, :reason],
                message: -> (_object, _data) { _('compliance violation has already been recorded') }
              }
    validates :reason, presence: true
    validates :severity_level, presence: true

    # The below violations need to either ignore or handle their errors to help prevent the merge process failing
    VIOLATIONS = [
      ::Gitlab::ComplianceManagement::Violations::ApprovedByMergeRequestAuthor,
      ::Gitlab::ComplianceManagement::Violations::ApprovedByCommitter,
      ::Gitlab::ComplianceManagement::Violations::ApprovedByInsufficientUsers
    ].freeze

    def self.process_merge_request(merge_request)
      VIOLATIONS.each do |violation_check|
        violation_check.new(merge_request).execute
      end
    end

    def self.sort_by_attribute(sort_option)
      case sort_option
      when 'SEVERITY_LEVEL_ASC' then reorder(severity_level: :asc, id: :asc)
      when 'SEVERITY_LEVEL_DESC' then reorder(severity_level: :desc, id: :desc)
      when 'VIOLATION_REASON_ASC' then reorder(reason: :asc, id: :asc)
      when 'VIOLATION_REASON_DESC' then reorder(reason: :desc, id: :desc)
      when 'MERGE_REQUEST_TITLE_ASC' then reorder(title: :asc, id: :asc)
      when 'MERGE_REQUEST_TITLE_DESC' then reorder(title: :desc, id: :desc)
      when 'MERGED_AT_ASC' then reorder(merged_at: :asc, id: :asc)
      when 'MERGED_AT_DESC' then reorder(merged_at: :desc, id: :desc)
      else reorder(severity_level: :desc, id: :desc) # rubocop: disable Lint/DuplicateBranch
      end
    end
  end
end
