# frozen_string_literal: true

module EE
  module API
    module Ci
      module Helpers
        module Runner
          extend ::Gitlab::Utils::Override

          override :track_ci_minutes_usage!
          def track_ci_minutes_usage!(build, runner)
            ::Ci::Minutes::TrackLiveConsumptionService.new(build).execute
          end
        end
      end
    end
  end
end
