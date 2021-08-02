# frozen_string_literal: true

module EE
  module Ci
    module BuildFinishedWorker
      def process_build(build)
        # Always run `super` first since it contains sync operations.
        # Failing to run sync operations would cause the worker to retry
        # and enqueueing duplicate jobs.
        super

        unless ::Feature.enabled?(:cancel_pipelines_prior_to_destroy, build.project, default_enabled: :yaml)
          ::Ci::Minutes::UpdateBuildMinutesService.new(build.project, nil).execute(build)
        end

        unless build.project.requirements.empty?
          RequirementsManagement::ProcessRequirementsReportsWorker.perform_async(build.id)
        end

        if ::Gitlab.com? && build.has_security_reports?
          ::Security::TrackSecureScansWorker.perform_async(build.id)
        end
      end
    end
  end
end
