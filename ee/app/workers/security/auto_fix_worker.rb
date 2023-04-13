# frozen_string_literal: true

module Security
  class AutoFixWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :software_composition_analysis

    idempotent!

    def perform(pipeline_id)
      return if Feature.disabled?(:security_auto_fix)

      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        project = pipeline.project

        break unless project.security_setting.auto_fix_enabled?

        Security::AutoFixService.new(project, pipeline).execute
      end
    end
  end
end
