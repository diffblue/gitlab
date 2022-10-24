# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      extend ActiveSupport::Concern

      EE_COUNTERS = [
        ::Gitlab::UsageDataCounters::LicensesList,
        ::Gitlab::StatusPage::UsageDataCounters::IncidentCounter,
        ::Gitlab::UsageDataCounters::LicenseTestingCounter
      ].freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :counters
        def counters
          super + EE_COUNTERS
        end
      end
    end
  end
end
