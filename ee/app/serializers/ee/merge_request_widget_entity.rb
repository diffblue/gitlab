# frozen_string_literal: true

module EE
  module MergeRequestWidgetEntity
    include ::API::Helpers::RelatedResourcesHelpers
    extend ActiveSupport::Concern

    prepended do
      expose :require_password_to_approve do |merge_request|
        merge_request.target_project.require_password_to_approve?
      end

      expose :merge_request_approvers_available do |merge_request|
        merge_request.target_project.licensed_feature_available?(:merge_request_approvers)
      end

      expose :multiple_approval_rules_available do |merge_request|
        merge_request.target_project.multiple_approval_rules_available?
      end

      expose :browser_performance, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:browser_performance) } do
        expose :degradation_threshold do |merge_request|
          merge_request.head_pipeline&.present(current_user: current_user)
            &.degradation_threshold(:browser_performance)
        end

        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:browser_performance)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:browser_performance)
        end
      end

      expose :load_performance, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:load_performance) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:load_performance)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:load_performance)
        end
      end

      expose :license_scanning, if: -> (mr, _) { can?(current_user, :read_licenses, mr.target_project) } do
        expose :can_manage_licenses do |merge_request|
          can?(current_user, :admin_software_license_policy, merge_request)
        end

        expose :settings_path, if: -> (mr, _) { can?(current_user, :admin_software_license_policy, mr.target_project) } do |merge_request|
          license_management_settings_path(merge_request.target_project)
        end

        expose :full_report_path, if: -> (mr, _) { mr.head_pipeline } do |merge_request|
          licenses_project_pipeline_path(merge_request.target_project, merge_request.head_pipeline)
        end
      end

      expose :metrics_reports_path, if: -> (mr, _) { mr.has_metrics_reports? } do |merge_request|
        metrics_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
      end

      expose :pipeline_id, if: -> (mr, _) { mr.head_pipeline } do |merge_request|
        merge_request.head_pipeline.id
      end

      expose :pipeline_iid, if: -> (mr, _) { mr.head_pipeline } do |merge_request|
        merge_request.head_pipeline.iid
      end

      expose :can_read_vulnerabilities do |merge_request|
        can?(current_user, :read_security_resource, merge_request.project)
      end

      expose :can_read_vulnerability_feedback do |merge_request|
        can?(current_user, :read_vulnerability_feedback, merge_request.project)
      end

      expose :vulnerability_feedback_path do |merge_request|
        project_vulnerability_feedback_index_path(merge_request.project)
      end

      expose :create_vulnerability_feedback_issue_path do |merge_request|
        presenter(merge_request).create_vulnerability_feedback_issue_path(merge_request.project)
      end

      expose :create_vulnerability_feedback_merge_request_path do |merge_request|
        presenter(merge_request).create_vulnerability_feedback_merge_request_path(merge_request.project)
      end

      expose :create_vulnerability_feedback_dismissal_path do |merge_request|
        presenter(merge_request).create_vulnerability_feedback_dismissal_path(merge_request.project)
      end

      expose :discover_project_security_path do |merge_request|
        presenter(merge_request).discover_project_security_path
      end

      expose :has_approvals_available do |merge_request|
        merge_request.approval_feature_available?
      end

      expose :api_approval_settings_path do |merge_request|
        presenter(merge_request).api_approval_settings_path
      end

      expose :merge_immediately_docs_path do |merge_request|
        presenter(merge_request).merge_immediately_docs_path
      end

      expose :blocking_merge_requests, if: -> (mr, _) { mr&.target_project&.feature_available?(:blocking_merge_requests) }

      private

      def blocking_merge_requests
        hidden_blocking_count = object.hidden_blocking_merge_requests_count(current_user)
        visible_mrs = object.visible_blocking_merge_requests(current_user)
        visible_mrs_by_state = visible_mrs
          .map { |mr| represent_blocking_mr(mr) }
          .group_by { |blocking_mr| blocking_mr.object.state_id_name }

        {
          total_count: visible_mrs.count + hidden_blocking_count,
          hidden_count: hidden_blocking_count,
          visible_merge_requests: visible_mrs_by_state
        }
      end
    end

    def represent_blocking_mr(blocking_mr)
      blocking_mr_options = options.merge(from_project: object.target_project)

      ::BlockingMergeRequestEntity.represent(blocking_mr, blocking_mr_options)
    end
  end
end
