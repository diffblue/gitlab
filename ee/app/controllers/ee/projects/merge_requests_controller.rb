# frozen_string_literal: true

module EE
  module Projects
    module MergeRequestsController
      extend ActiveSupport::Concern

      prepended do
        include DescriptionDiffActions

        before_action only: [:show] do
          push_frontend_feature_flag(:anonymous_visual_review_feedback)
          push_frontend_feature_flag(:missing_mr_security_scan_types, @project)
          push_frontend_feature_flag(:usage_data_i_testing_metrics_report_widget_total, @project, default_enabled: true)
          push_frontend_feature_flag(:usage_data_i_testing_web_performance_widget_total, @project, default_enabled: true)
          push_frontend_feature_flag(:usage_data_i_testing_load_performance_widget_total, @project, default_enabled: true)
        end

        before_action :authorize_read_pipeline!, only: [:container_scanning_reports, :dependency_scanning_reports,
                                                        :sast_reports, :secret_detection_reports, :dast_reports,
                                                        :metrics_reports, :coverage_fuzzing_reports,
                                                        :api_fuzzing_reports]
        before_action :authorize_read_licenses!, only: [:license_scanning_reports]

        feature_category :code_review, [:delete_description_version, :description_diff]
        feature_category :container_scanning, [:container_scanning_reports]
        feature_category :dependency_scanning, [:dependency_scanning_reports]
        feature_category :fuzz_testing, [:coverage_fuzzing_reports, :api_fuzzing_reports]
        feature_category :license_compliance, [:license_scanning_reports]
        feature_category :vulnerability_management, [:sast_reports, :secret_detection_reports]
        feature_category :dynamic_application_security_testing, [:dast_reports]
        feature_category :metrics, [:metrics_reports]
      end

      def license_scanning_reports
        reports_response(merge_request.compare_license_scanning_reports(current_user))
      end

      def container_scanning_reports
        reports_response(merge_request.compare_container_scanning_reports(current_user), head_pipeline)
      end

      def dependency_scanning_reports
        reports_response(merge_request.compare_dependency_scanning_reports(current_user), head_pipeline)
      end

      def dast_reports
        reports_response(merge_request.compare_dast_reports(current_user), head_pipeline)
      end

      def metrics_reports
        reports_response(merge_request.compare_metrics_reports)
      end

      def coverage_fuzzing_reports
        reports_response(merge_request.compare_coverage_fuzzing_reports(current_user), head_pipeline)
      end

      def api_fuzzing_reports
        reports_response(merge_request.compare_api_fuzzing_reports(current_user), head_pipeline)
      end
    end
  end
end
