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
          super.merge(minutes_exceeded: minutes_exceeded?(build.project))
        end

        private

        def minutes_exceeded?(project)
          ::Ci::Runner.any_shared_runners_with_enabled_cost_factor?(project) &&
            project.ci_minutes_usage.minutes_used_up?
        end
      end
    end
  end
end
