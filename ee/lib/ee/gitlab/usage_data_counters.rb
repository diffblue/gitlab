# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      extend ActiveSupport::Concern

      EE_COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES = [
        ::Gitlab::UsageDataCounters::LicensesList,
        ::Gitlab::StatusPage::UsageDataCounters::IncidentCounter,
        ::Gitlab::UsageDataCounters::LicenseTestingCounter
      ].freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        private

        override :migrated_counters
        def migrated_counters
          super + EE_COUNTERS_MIGRATED_TO_INSTRUMENTATION_CLASSES
        end
      end
    end
  end
end
