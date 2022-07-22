# frozen_string_literal: true

module EE
  module Projects
    module PipelineHelper
      extend ::Gitlab::Utils::Override

      override :js_pipeline_tabs_data
      def js_pipeline_tabs_data(project, pipeline, user)
        super.merge(
          codequality_report_download_path: codequality_report_download_path(project, pipeline),
          expose_license_scanning_data: pipeline.expose_license_scanning_data?.to_json,
          expose_security_dashboard: pipeline.expose_security_dashboard?.to_json,
          vulnerability_report_data: vulnerability_report_data(project, pipeline, user).to_json,
          license_management_api_url: license_management_api_url(project),
          license_management_settings_path: license_management_path(user, project),
          licenses_api_path: licenses_api_path(project, pipeline),
          can_manage_licenses: user&.can?(:admin_software_license_policy, project).to_s
        )
      end

      def license_management_path(user, project)
        if user&.can?(:admin_software_license_policy, project)
          license_management_settings_path(project)
        end
      end

      def licenses_api_path(project, pipeline)
        if project.licensed_feature_available?(:license_scanning)
          licenses_project_pipeline_path(project, pipeline)
        end
      end

      def codequality_report_download_path(project, pipeline)
        return unless project.licensed_feature_available?(:full_codequality_report)

        pipeline.downloadable_path_for_report_type(:codequality)
      end

      def vulnerability_report_data(project, pipeline, user)
        ::Security::VulnerabilityReportDataSerializer.new.represent(pipeline, project: project, user: user)
      end
    end
  end
end
