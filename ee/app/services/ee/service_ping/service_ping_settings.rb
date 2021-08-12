# frozen_string_literal: true

module EE
  module ServicePing
    module ServicePingSettings
      extend ::Gitlab::Utils::Override

      override :enabled?
      def enabled?
        ::License.current&.customer_service_enabled? || super
      end
    end
  end
end
