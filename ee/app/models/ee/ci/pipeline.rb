# frozen_string_literal: true

module EE
  module Ci
    module Pipeline
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include UsageStatistics

        has_many :vulnerabilities_finding_pipelines, class_name: 'Vulnerabilities::FindingPipeline', inverse_of: :pipeline
        has_many :vulnerability_findings, source: :finding, through: :vulnerabilities_finding_pipelines, class_name: 'Vulnerabilities::Finding'

        has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: 'auto_canceled_by_id'
        has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: 'auto_canceled_by_id'

        # Subscriptions to this pipeline
        has_many :downstream_bridges, class_name: '::Ci::Bridge', foreign_key: :upstream_pipeline_id
        has_many :security_scans, class_name: 'Security::Scan', through: :builds
        has_many :security_findings, class_name: 'Security::Finding', through: :security_scans, source: :findings

        has_one :dast_profiles_pipeline, class_name: 'Dast::ProfilesPipeline', foreign_key: :ci_pipeline_id, inverse_of: :ci_pipeline
        has_one :dast_profile, class_name: 'Dast::Profile', through: :dast_profiles_pipeline

        # Temporary location to be moved in the future. Please see gitlab-org/gitlab#330950 for more info.
        has_one :dast_site_profiles_pipeline, class_name: 'Dast::SiteProfilesPipeline', foreign_key: :ci_pipeline_id, inverse_of: :ci_pipeline
        has_one :dast_site_profile, class_name: 'DastSiteProfile', through: :dast_site_profiles_pipeline

        has_one :source_project, class_name: 'Ci::Sources::Project', foreign_key: :pipeline_id

        # Legacy way to fetch security reports based on job name. This has been replaced by the reports feature.
        scope :with_legacy_security_reports, -> do
          joins(:downloadable_artifacts).where(ci_builds: { name: %w[sast secret_detection dependency_scanning container_scanning dast] })
        end

        scope :with_vulnerabilities, -> do
          where('EXISTS (?)', ::Vulnerabilities::FindingPipeline.where('ci_pipelines.id=vulnerability_occurrence_pipelines.pipeline_id').select(1))
        end

        # This structure describes feature levels
        # to access the file types for given reports
        REPORT_LICENSED_FEATURES = {
          codequality: nil,
          sast: %i[sast],
          secret_detection: %i[secret_detection],
          dependency_scanning: %i[dependency_scanning],
          container_scanning: %i[container_scanning],
          cluster_image_scanning: %i[cluster_image_scanning],
          dast: %i[dast],
          performance: %i[merge_request_performance_metrics],
          browser_performance: %i[merge_request_performance_metrics],
          load_performance: %i[merge_request_performance_metrics],
          license_scanning: %i[license_scanning],
          metrics: %i[metrics_reports],
          requirements: %i[requirements],
          coverage_fuzzing: %i[coverage_fuzzing],
          api_fuzzing: %i[api_fuzzing]
        }.freeze

        state_machine :status do
          after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
            next unless pipeline.can_store_security_reports?

            pipeline.run_after_commit do
              ::Security::StoreScansWorker.perform_async(pipeline.id)
            end
          end

          after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
            pipeline.run_after_commit do
              ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(pipeline.id)
            end
          end

          after_transition any => ::Ci::Pipeline.bridgeable_statuses.map(&:to_sym) do |pipeline|
            next unless pipeline.downstream_bridges.any?

            pipeline.run_after_commit do
              ::Ci::PipelineBridgeStatusWorker.perform_async(pipeline.id)
            end
          end

          after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
            next unless pipeline.triggers_subscriptions?

            pipeline.run_after_commit do
              ::Ci::TriggerDownstreamSubscriptionsWorker.perform_async(pipeline.id)
            end
          end
        end
      end

      def needs_touch?
        updated_at < 5.minutes.ago
      end

      def triggers_subscriptions?
        # Currently we trigger subscriptions only for tags.
        tag? && project_has_subscriptions?
      end

      def batch_lookup_report_artifact_for_file_type(file_type)
        return unless available_licensed_report_type?(file_type)

        super
      end

      def expose_license_scanning_data?
        batch_lookup_report_artifact_for_file_type(:license_scanning).present?
      end

      def license_scanning_report
        ::Gitlab::Ci::Reports::LicenseScanning::Report.new.tap do |license_scanning_report|
          latest_report_builds(::Ci::JobArtifact.license_scanning_reports).each do |build|
            build.collect_license_scanning_reports!(license_scanning_report)
          end
        end
      end

      def dependency_list_report
        ::Gitlab::Ci::Reports::DependencyList::Report.new.tap do |dependency_list_report|
          latest_report_builds(::Ci::JobArtifact.dependency_list_reports).each do |build|
            build.collect_dependency_list_reports!(dependency_list_report)
          end
          latest_report_builds(::Ci::JobArtifact.license_scanning_reports).each do |build|
            build.collect_licenses_for_dependency_list!(dependency_list_report)
          end
        end
      end

      def metrics_report
        ::Gitlab::Ci::Reports::Metrics::Report.new.tap do |metrics_report|
          latest_report_builds(::Ci::JobArtifact.metrics_reports).each do |build|
            build.collect_metrics_reports!(metrics_report)
          end
        end
      end

      ##
      # Check if it's a merge request pipeline with the HEAD of source and target branches
      # TODO: Make `Ci::Pipeline#latest?` compatible with merge request pipelines and remove this method.
      def latest_merged_result_pipeline?
        merged_result_pipeline? &&
          source_sha == merge_request.diff_head_sha &&
          target_sha == merge_request.target_branch_sha
      end

      override :merge_request_event_type
      def merge_request_event_type
        return unless merge_request?

        strong_memoize(:merge_request_event_type) do
          merge_train_pipeline? ? :merge_train : super
        end
      end

      override :merge_train_pipeline?
      def merge_train_pipeline?
        merged_result_pipeline? && merge_train_ref?
      end

      def latest_failed_security_builds
        security_builds.select(&:latest?)
                       .select(&:failed?)
      end

      def license_scan_completed?
        latest_report_builds(::Ci::JobArtifact.license_scanning_reports).exists?
      end

      def can_store_security_reports?
        project.can_store_security_reports? && has_security_reports?
      end

      def has_security_findings?
        security_findings.exists?
      end

      def triggered_for_ondemand_dast_scan?
        ondemand_dast_scan? && parameter_source?
      end

      private

      def has_security_reports?
        has_reports?(::Ci::JobArtifact.security_reports.or(::Ci::JobArtifact.license_scanning_reports))
      end

      def project_has_subscriptions?
        project.feature_available?(:ci_project_subscriptions) &&
          project.downstream_projects.any?
      end

      def merge_train_ref?
        ::MergeRequest.merge_train_ref?(ref)
      end

      def available_licensed_report_type?(file_type)
        feature_names = REPORT_LICENSED_FEATURES.fetch(file_type)
        feature_names.nil? || feature_names.any? { |feature| project.feature_available?(feature) }
      end

      def security_builds
        @security_builds ||= ::Security::SecurityJobsFinder.new(pipeline: self).execute
      end
    end
  end
end
