# frozen_string_literal: true

module ComplianceManagement
  module MergeRequests
    class ComplianceViolationsConsistencyService
      def initialize(compliance_violation)
        @compliance_violation = compliance_violation
      end

      def execute
        inconsistent_attributes = find_inconsistent_attributes

        update_compliance_violation(inconsistent_attributes)
      end

      private

      attr_accessor :compliance_violation

      def find_inconsistent_attributes
        inconsistent_attributes = {}
        merge_request = compliance_violation.merge_request

        inconsistent_attributes[:title] = merge_request.title if compliance_violation.title != merge_request.title

        if merge_request.merged_at != compliance_violation.merged_at
          inconsistent_attributes[:merged_at] = merge_request.merged_at
        end

        if compliance_violation.target_branch != merge_request.target_branch
          inconsistent_attributes[:target_branch] = merge_request.target_branch
        end

        if merge_request.target_project_id != compliance_violation.target_project_id
          inconsistent_attributes[:target_project_id] = merge_request.target_project_id
        end

        inconsistent_attributes
      end

      def update_compliance_violation(inconsistent_attributes)
        return if inconsistent_attributes.blank?

        compliance_violation.update!(inconsistent_attributes)
      end
    end
  end
end
