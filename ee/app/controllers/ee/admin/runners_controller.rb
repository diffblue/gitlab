# frozen_string_literal: true

module EE
  module Admin
    module RunnersController
      extend ActiveSupport::Concern

      prepended do
        before_action(only: [:index]) { push_licensed_feature(:runner_performance_insights) }
        before_action(only: [:index, :show]) do
          push_licensed_feature(:runner_upgrade_management) if ::Gitlab::Ci::RunnerReleases.instance.enabled?
        end
        before_action(only: [:new, :show, :edit]) { push_licensed_feature(:runner_maintenance_note) }
      end

      def dashboard
        dashboard_available = ::Feature.enabled?(:runners_dashboard) &&
          License.feature_available?(:runner_performance_insights)

        render_404 unless dashboard_available
      end
    end
  end
end
