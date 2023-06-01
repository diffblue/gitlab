# frozen_string_literal: true

module Llm
  class AnalyzeCiJobFailureService < BaseService
    extend ::Gitlab::Utils::Override

    override :valid
    def valid?
      super &&
        ::License.feature_available?(:ai_analyze_ci_job_failure) &&
        Feature.enabled?(:ai_build_failure_cause, resource.resource_parent) &&
        user.can?(:read_build_trace, resource)
    end

    private

    # no-op since the feature is in development
    def perform
      success
    end
  end
end
