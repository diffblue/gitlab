# frozen_string_literal: true

module RegistrationFeatures
  class MaintenanceMode
    def self.feature_available?
      ::Gitlab::Geo.license_allows? || ::GitlabSubscriptions::Features.usage_ping_feature?(:maintenance_mode)
    end
  end
end
