# frozen_string_literal: true

module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Deployment` model
  module Deployment
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics

      delegate :needs_approval?, to: :environment
      delegate :allow_pipeline_trigger_approve_deployment, to: :project

      has_many :approvals, class_name: 'Deployments::Approval'

      scope :with_approvals, -> { preload(approvals: [:user]) }

      state_machine :status do
        after_transition created: :blocked do |deployment, transition|
          deployment.run_after_commit do
            next unless deployment.allow_pipeline_trigger_approve_deployment

            # Try to approve deployment automatically.
            # Even if the approval cannot be completed due to some conditions (such as
            # insufficient permissions), there are no other side effects.
            ::Deployments::ApprovalWorker.perform_async(deployment.id, user_id: deployment.user_id, status: 'approved')
          end
        end
      end

      Dora::Watchers.mount(self)
    end

    def pending_approval_count
      return 0 unless blocked?

      environment.required_approval_count - approvals.length
    end

    def approval_summary
      strong_memoize(:approval_summary) do
        ::Deployments::ApprovalSummary.new(deployment: self)
      end
    end

    def approved?
      approval_summary.status == ::Deployments::ApprovalSummary::STATUS_APPROVED
    end
  end
end
