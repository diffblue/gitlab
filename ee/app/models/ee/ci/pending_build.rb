# frozen_string_literal: true

module EE
  module Ci
    module PendingBuild
      extend ActiveSupport::Concern

      prepended do
        scope :with_ci_minutes_available, -> { where(minutes_exceeded: false) }
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        override :args_from_build
        def args_from_build(build)
          return super unless ::Feature.enabled?(
            :ci_pending_builds_maintain_ci_minutes_data,
            build&.project&.root_namespace,
            type: :development,
            default_enabled: :yaml
          )

          super.merge(minutes_exceeded: minutes_exceeded?(build.project))
        end

        private

        def minutes_exceeded?(project)
          ::Ci::Runner.any_shared_runners_with_enabled_cost_factor?(project) &&
            project.ci_minutes_quota.actual_minutes_used_up?
        end
      end
    end
  end
end
