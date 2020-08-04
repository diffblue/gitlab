# frozen_string_literal: true

module EE
  module Projects
    module PipelinesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :authorize_read_licenses!, only: [:licenses]
      end

      def security
        if pipeline.expose_security_dashboard?
          push_frontend_feature_flag(:pipelines_security_report_summary, default_enabled: false)
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      def licenses
        report_exists = pipeline.expose_license_scanning_data?
        return access_to_licenses_denied! unless report_exists

        respond_to do |format|
          format.html { render_show }
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
