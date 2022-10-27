# frozen_string_literal: true

module ProtectedEnvironments
  module ApprovalRules
    module Summarizable
      extend ActiveSupport::Concern

      def approved_count
        approvals_for_summary.count(&:approved?)
      end

      def approved?
        approved_count >= required_approvals
      end

      def rejected?
        approvals_for_summary.any?(&:rejected?)
      end

      def status
        return Deployments::ApprovalSummary::STATUS_REJECTED if rejected?
        return Deployments::ApprovalSummary::STATUS_APPROVED if approved?

        Deployments::ApprovalSummary::STATUS_PENDING_APPROVAL
      end

      def pending_approval_count
        [required_approvals - approved_count, 0].max
      end

      def approvals_for_summary
        @approvals_for_summary ||= [] # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def approvals_for_summary=(approvals)
        @approvals_for_summary = approvals || [] # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
