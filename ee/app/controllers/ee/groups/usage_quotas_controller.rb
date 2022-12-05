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
        before_action do
          push_frontend_feature_flag(:usage_quotas_pipelines_vue, group)
        end
      end

      def pending_members
        render_404 unless group.user_cap_available?
      end

      private

      override :verify_usage_quotas_enabled!
      def verify_usage_quotas_enabled!
        render_404 unless ::License.feature_available?(:usage_quotas)
        render_404 if group.has_parent?
      end

      override :seat_count_data
      def seat_count_data
        generate_seat_count_alert_data(group)
      end

      override :current_namespace_usage
      def current_namespace_usage
        ::Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: group.id)
      end

      override :projects_usage
      def projects_usage
        ::Ci::Minutes::ProjectMonthlyUsage
                        .for_namespace_monthly_usage(current_namespace_usage)
                        .page(params[:page])
      end
    end
  end
end
