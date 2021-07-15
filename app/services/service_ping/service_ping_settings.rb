# frozen_string_literal: true

module ServicePing
  module ServicePingSettings
    class << self
      def product_intelligence_enabled?
        pings_enabled? && !User.single_user&.requires_usage_stats_consent?
      end

      private

      def pings_enabled?
        ::Gitlab::CurrentSettings.usage_ping_enabled?
      end
    end
  end
end
