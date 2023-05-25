# frozen_string_literal: true

module EE
  module PlanLimits
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :dashboard_storage_limit_enabled?
    def dashboard_storage_limit_enabled?
      # storage_size_limit is the "dashboard" storage limit
      dashboard_limit_enabled_at.present? &&
        storage_size_limit > 0
    end
  end
end
