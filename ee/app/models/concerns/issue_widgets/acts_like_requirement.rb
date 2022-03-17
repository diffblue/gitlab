# frozen_string_literal: true

module IssueWidgets
  module ActsLikeRequirement
    extend ActiveSupport::Concern

    included do
      attr_accessor :requirement_sync_error

      after_validation :invalidate_if_sync_error, on: [:update, :create]

      has_many :test_reports, foreign_key: :issue_id, inverse_of: :requirement_issue, class_name: 'RequirementsManagement::TestReport'

      has_one :requirement, class_name: 'RequirementsManagement::Requirement'

      scope :for_requirement_iids, -> (requirements_iids) do
        requirement.joins(:requirement)
          .where(requirement: { iid: requirements_iids })
          .where('requirement.project_id = issues.project_id') # Prevents filtering too many rows by iids. Greatly increases performance.
      end
    end

    def requirement_sync_error!
      self.requirement_sync_error = true
    end

    def invalidate_if_sync_error
      return unless requirement? # No need to invalidate if issue_type != requirement
      return unless requirement_sync_error
      return unless requirement

      # Mirror errors from requirement so that users can adjust accordingly
      errors = requirement.errors.full_messages.to_sentence
      errors = errors.presence || "Associated requirement was invalid and changes could not be applied."
      self.errors.add(:base, errors)
    end
  end
end
