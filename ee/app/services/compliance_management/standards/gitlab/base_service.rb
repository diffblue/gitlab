# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class BaseService < BaseProjectService
        STANDARD = :gitlab

        private

        def feature_not_available
          ServiceResponse.error(message: "Compliance standards adherence feature not available")
        end

        def unavailable_for_user_namespace
          ServiceResponse.error(message: "Compliance standards adherence is not available for user namespace")
        end
      end
    end
  end
end
