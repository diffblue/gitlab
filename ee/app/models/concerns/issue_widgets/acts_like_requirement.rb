# frozen_string_literal: true

module IssueWidgets
  module ActsLikeRequirement
    extend ActiveSupport::Concern

    included do
      attr_accessor :requirement_sync_error

      validate :same_project_of_requirement

      after_validation :invalidate_if_sync_error, on: [:update, :create]

      has_many :test_reports, foreign_key: :issue_id, inverse_of: :requirement_issue, class_name: 'RequirementsManagement::TestReport'

      has_one :requirement, class_name: 'RequirementsManagement::Requirement'

      scope :for_requirement_iids, -> (requirements_iids) do
        base_scope = if Feature.enabled?(:issue_type_uses_work_item_types_table)
                       joins(:work_item_type).where(
                         work_item_type: { base_type: WorkItems::Type.base_types[:requirement] }
                       )
                     else
                       requirement
                     end

        base_scope.joins(:requirement)
          .where(requirement: { iid: requirements_iids })
          .where('requirement.project_id = issues.project_id') # Prevents filtering too many rows by iids. Greatly increases performance.
      end
    end

    def requirement_sync_error!
      self.requirement_sync_error = true
    end

    def invalidate_if_sync_error
      return unless work_item_type&.requirement? # No need to invalidate if work_item_type != requirement
      return unless requirement_sync_error
      return unless requirement

      # Mirror errors from requirement so that users can adjust accordingly
      errors = requirement.errors.full_messages.to_sentence
      errors = errors.presence || "Associated requirement was invalid and changes could not be applied."
      self.errors.add(:base, errors)
    end

    def same_project_of_requirement
      return if requirement&.project_id.nil? || project_id.nil?
      return if project_id == requirement.project_id

      errors.add(:project_id, _('must belong to same project of its requirement object.'))
    end
  end
end
