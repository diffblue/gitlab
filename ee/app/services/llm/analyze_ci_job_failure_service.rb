# frozen_string_literal: true

module Llm
  class AnalyzeCiJobFailureService < BaseService
    extend ::Gitlab::Utils::Override

    alias_method :job, :resource

    override :valid
    def valid?
      super &&
        user.can?(:read_build_trace, job) &&
        Feature.enabled?(:ai_build_failure_cause, job.project) &&
        job.project.licensed_feature_available?(:ai_analyze_ci_job_failure) &&
        Gitlab::Llm::StageCheck.available?(job.resource_parent, :ai_analyze_ci_job_failure)
    end

    private

    def perform
      worker_perform(user, job, :analyze_ci_job_failure, options)
    end
  end
end
