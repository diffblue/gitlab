# frozen_string_literal: true

module IssueWidgets
  module ActsLikeRequirement
    extend ActiveSupport::Concern

    included do
      # This will mean that non-Requirement issues essentially ignore this relationship and always return []
      has_many :test_reports, -> { joins(:requirement_issue).where(issues: { issue_type: WorkItem::Type.base_types[:requirement] }) },
               foreign_key: :issue_id, inverse_of: :requirement_issue, class_name: 'RequirementsManagement::TestReport'
      has_one :requirement, class_name: 'RequirementsManagement::Requirement'
    end
  end
end
