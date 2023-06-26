# frozen_string_literal: true

module EE
  module Projects
    module PipelinesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :authorize_read_licenses!, only: [:licenses]
        before_action do
          push_frontend_feature_flag(:pipeline_security_dashboard_graphql, project, type: :development)
          push_frontend_feature_flag(:deprecate_vulnerabilities_feedback, project, type: :development)
          push_frontend_feature_flag(:standalone_finding_modal, project, type: :development)
          push_frontend_feature_flag(:dora_charts_forecast, project.namespace)
        end

        feature_category :software_composition_analysis, [:licenses]
        feature_category :vulnerability_management, [:security]
        feature_category :code_quality, [:codequality_report]

        urgency :low, [:codequality_report, :licenses, :security]
      end

      def security
        if pipeline.expose_security_dashboard?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      def licenses
        scanner = ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline)
        return access_to_licenses_denied! unless scanner.has_data?

        respond_to do |format|
          format.html do
            render_show
          end
          format.json do
            render status: :ok, json: LicenseScanningReportsSerializer.new.represent(
              project.license_compliance(pipeline).find_policies(detected_only: true)
            )
          end
        end
      end

      def codequality_report
        render_show
      end

      private

      # This overrides the default implementation
      # because this controller chose to respond with a 302 instead of a 404
      def authorize_read_licenses!
        access_to_licenses_denied! unless can?(current_user, :read_licenses, project)
      end

      def access_to_licenses_denied!
        respond_to do |format|
          format.html { redirect_to pipeline_path(pipeline) }
          format.json { head :not_found }
        end
      end
    end
  end
end
