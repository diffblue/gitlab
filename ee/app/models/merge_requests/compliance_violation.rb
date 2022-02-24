# frozen_string_literal: true

module MergeRequests
  class ComplianceViolation < ApplicationRecord
    include BulkInsertSafe

    self.table_name = 'merge_requests_compliance_violations'

    enum reason: ::Enums::MergeRequests::ComplianceViolation.reasons
    enum severity_level: ::Enums::MergeRequests::ComplianceViolation.severity_levels

    scope :with_merge_requests, -> { preload(merge_request: [{ target_project: :namespace }, :metrics]) }
    scope :join_projects, -> { with_merge_requests.joins(merge_request: { target_project: :namespace }) }

    scope :by_approved_by_committer, -> { where(reason: ::Gitlab::ComplianceManagement::Violations::ApprovedByCommitter::REASON) }
    scope :by_group, -> (group) { join_projects.where(merge_requests: { projects: { namespace_id: group.self_and_descendants } }) }

    scope :order_by_severity_level, -> (direction) { order(severity_level: direction, id: direction) }

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
  end
end
