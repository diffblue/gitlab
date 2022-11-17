# frozen_string_literal: true

module Projects
  module Pipelines
    class EmailCampaignsController < Projects::Pipelines::ApplicationController
      before_action :check_if_gl_com_or_dev

      feature_category :experimentation_activation
      urgency :low

      def validate_account
        track_email_cta_click

        session[:start_account_validation] = true

        redirect_to project_pipeline_path(project, pipeline)
      end

      private

      def track_email_cta_click
        ::Gitlab::Tracking.event(
          self.class.name,
          'cta_clicked',
          label: 'account_validation_email',
          project: project,
          user: current_user,
          namespace: project.root_namespace
        )
      end
    end
  end
end
