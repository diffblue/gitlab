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

      Dora::Watchers.mount(self)
    end

    def waiting_for_approval?
      if ::Feature.enabled?(:dynamically_compute_deployment_approval, project)
        pending_approval_count > 0
      else
        blocked?
      end
    end

    def pending_approval_count
      if ::Feature.disabled?(:dynamically_compute_deployment_approval, project)
        return 0 unless blocked? # rubocop:disable Style/SoleNestedConditional
      end

      required_approval_count = environment.required_approval_count

      return 0 unless required_approval_count > 0

      [required_approval_count - approvals.length, 0].max
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
