# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class LicenseTestingCounter < BaseCounter
      KNOWN_EVENTS = %w[clicking_license_testing_visiting_external_website visiting_testing_license_compliance_full_report].freeze
      PREFIX = 'users'
    end
  end
end
