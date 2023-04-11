# frozen_string_literal: true

module EE
  module Groups
    module UsageQuotasController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      include OneTrustCSP
      include GoogleAnalyticsCSP
      include GitlabSubscriptions::SeatCountAlert

      prepended do
        before_action only: [:index] do
          push_frontend_feature_flag(:data_transfer_monitoring, group)
        end
      end

      def pending_members
        render_404 unless group.user_cap_available?
      end

      private

      override :seat_count_data
      def seat_count_data
        generate_seat_count_alert_data(group)
      end
    end
  end
end
