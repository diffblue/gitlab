# frozen_string_literal: true

# EE:SaaS
module Groups
  class FeatureDiscoveryMomentsController < Groups::ApplicationController
    feature_category :experimentation_conversion

    before_action :ensure_group_eligible_for_trial!, only: :advanced_features_dashboard
    before_action :authorize_admin_group!, only: :advanced_features_dashboard

    layout 'application'

    def advanced_features_dashboard
    end

    private

    def ensure_group_eligible_for_trial!
      return render_404 unless Gitlab::CurrentSettings.should_check_namespace_plan?
      return render_404 unless @group&.persisted? && @group&.plan_eligible_for_trial?
    end
  end
end
