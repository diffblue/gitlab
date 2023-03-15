# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :counters
        def counters
          super + [
            ::Gitlab::UsageDataCounters::LicensesList,
            ::Gitlab::StatusPage::UsageDataCounters::IncidentCounter,
            ::Gitlab::UsageDataCounters::LicenseTestingCounter,
            ::Gitlab::UsageDataCounters::ValueStreamsDashboardCounter
          ]
        end
      end
    end
  end
end
