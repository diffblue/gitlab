# frozen_string_literal: true

module EE
  module AlertManagement
    module HttpIntegrationsFinder
      extend ::Gitlab::Utils::Override

      private

      override :filter_by_availability
      def filter_by_availability
        super unless project.feature_available?(:multiple_alert_http_integrations)
      end
    end
  end
end
