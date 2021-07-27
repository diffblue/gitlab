# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Quota
          class JobActivity < ::Gitlab::Ci::Limit
            include ::Gitlab::Utils::StrongMemoize
            include ActionView::Helpers::TextHelper

            def initialize(namespace, project)
              @namespace = namespace
              @project = project
            end

            def enabled?
              ci_active_jobs_limit > 0
            end

            def exceeded?
              return false unless enabled?

              jobs_in_alive_pipelines_count > ci_active_jobs_limit
            end

            def message
              return unless exceeded?

              'Project has too many active jobs created in the last 24 hours! ' \
                "There are #{pluralize(jobs_in_alive_pipelines_count, 'active job')}, " \
                "but the limit is #{ci_active_jobs_limit}."
            end

            private

            def excessive_jobs_count
              @excessive ||= jobs_in_alive_pipelines_count - ci_active_jobs_limit
            end

            def jobs_in_alive_pipelines_count
              strong_memoize(:jobs_in_alive_pipelines_count) do
                @project.all_pipelines.jobs_count_in_alive_pipelines
              end
            end

            def ci_active_jobs_limit
              strong_memoize(:ci_active_jobs_limit) do
                @namespace.actual_limits.ci_active_jobs
              end
            end
          end
        end
      end
    end
  end
end
