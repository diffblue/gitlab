# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class UserCapSettingEnabledMetric < ::Gitlab::Usage::Metrics::Instrumentations::GenericMetric
          value do
            ::Gitlab::CurrentSettings.new_user_signups_cap
          end
        end
      end
    end
  end
end
