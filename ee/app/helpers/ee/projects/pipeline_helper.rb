# frozen_string_literal: true

module EE
  module Projects
    module PipelineHelper
      extend ::Gitlab::Utils::Override

      override :js_pipeline_tabs_data
      def js_pipeline_tabs_data(project, pipeline)
        super.merge(
          codequality_report_download_path: codequality_report_download_path(project, pipeline),
          expose_license_scanning_data: pipeline.expose_license_scanning_data?.to_json,
          expose_security_dashboard: pipeline.expose_security_dashboard?.to_json
        )
      end

      def codequality_report_download_path(project, pipeline)
        return unless project.licensed_feature_available?(:full_codequality_report)

        pipeline.downloadable_path_for_report_type(:codequality)
      end

      def vulnerability_report_data(project, pipeline, user)
        vulnerabilities_endpoint_path = expose_path(
          api_v4_projects_vulnerability_findings_path(
            id: project.id, params: { pipeline_id: pipeline.id }
          )
        )
        vulnerability_exports_endpoint_path = expose_path(
          api_v4_security_projects_vulnerability_exports_path(
            id: project.id
          )
        )

        {
          empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
          pipeline_id: pipeline.id,
          pipeline_iid: pipeline.iid,
          project_id: project.id,
          source_branch: pipeline.source_ref,
          pipeline_jobs_path: expose_path(
            api_v4_projects_pipelines_jobs_path(id: project.id, pipeline_id: pipeline.id)
          ),
          vulnerabilities_endpoint: vulnerabilities_endpoint_path,
          vulnerability_exports_endpoint: vulnerability_exports_endpoint_path,
          empty_state_unauthorized_svg_path: image_path('illustrations/user-not-logged-in.svg'),
          empty_state_forbidden_svg_path: image_path('illustrations/lock_promotion.svg'),
          project_full_path: project.path_with_namespace,
          commit_path_template: commit_path_template(project),
          can_admin_vulnerability: can?(user, :admin_vulnerability, project).to_s,
          can_view_false_positive: project.licensed_feature_available?(:sast_fp_reduction).to_s
        }
      end
    end
  end
end
