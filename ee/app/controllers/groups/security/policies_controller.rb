# frozen_string_literal: true

module Groups
  module Security
    class PoliciesController < Groups::ApplicationController
      before_action :authorize_group_security_policies!

      before_action do
        push_frontend_feature_flag(:group_level_security_policies, group, default_enabled: :yaml)
      end

      feature_category :security_orchestration

      def edit
        @policy_name = URI.decode_www_form_component(params[:id])
      end

      def index
        render :index, locals: { group: group }
      end

      private

      def authorize_group_security_policies!
        render_404 unless Feature.enabled?(:group_level_security_policies, group, default_enabled: :yaml)
      end
    end
  end
end
