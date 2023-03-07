# frozen_string_literal: true

module EE
  module Ci
    # Build EE mixin
    #
    # This module is intended to encapsulate EE-specific model logic
    # and be included in the `Build` model
    module Build
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      VALIDATE_SCHEMA_VARIABLE_NAME = 'VALIDATE_SCHEMA'
      LICENSED_PARSER_FEATURES = {
        sast: :sast,
        secret_detection: :secret_detection,
        dependency_scanning: :dependency_scanning,
        container_scanning: :container_scanning,
        cluster_image_scanning: :cluster_image_scanning,
        dast: :dast,
        coverage_fuzzing: :coverage_fuzzing,
        api_fuzzing: :api_fuzzing
      }.with_indifferent_access.freeze

      EE_RUNNER_FEATURES = {
        vault_secrets: -> (build) { build.ci_secrets_management_available? && build.secrets? }
      }.freeze

      prepended do
        include UsageStatistics
        include FromUnion

        has_many :security_scans, class_name: 'Security::Scan', foreign_key: :build_id

        has_one :dast_site_profiles_build, class_name: 'Dast::SiteProfilesBuild', foreign_key: :ci_build_id
        has_one :dast_site_profile, class_name: 'DastSiteProfile', through: :dast_site_profiles_build, disable_joins: true

        has_one :dast_scanner_profiles_build, class_name: 'Dast::ScannerProfilesBuild', foreign_key: :ci_build_id
        has_one :dast_scanner_profile, class_name: 'DastScannerProfile', through: :dast_scanner_profiles_build, disable_joins: true

        after_commit :track_ci_secrets_management_usage, on: :create
        delegate :service_specification, to: :runner_session, allow_nil: true

        scope :license_scan, -> { joins(:job_artifacts).merge(::Ci::JobArtifact.of_report_type(:license_scanning)) }
        scope :sbom_generation, -> { joins(:job_artifacts).merge(::Ci::JobArtifact.of_report_type(:sbom)) }
        scope :max_build_id_by, -> (build_name, ref, project_path) do
          select("max(#{quoted_table_name}.id) as id")
            .by_name(build_name)
            .for_ref(ref)
            .for_project_paths(project_path)
        end

        state_machine :status do
          after_transition any => [:success, :failed, :canceled] do |build|
            build.run_after_commit do
              ::Ci::Minutes::UpdateBuildMinutesService.new(build.project, nil).execute(build)
            end
          end
        end
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        override :clone_accessors
        def clone_accessors
          (super + %i[secrets]).freeze
        end
      end

      override :variables
      def variables
        strong_memoize(:variables) do
          super.tap do |collection|
            collection.concat(dast_configuration_variables)
          end
        end
      end

      def cost_factor_enabled?
        runner&.cost_factor_enabled?(project)
      end

      def log_geo_deleted_event
        # It is not needed to generate a Geo deleted event
        # since Legacy Artifacts are migrated to multi-build artifacts
        # See https://gitlab.com/gitlab-org/gitlab-foss/issues/46652
      end

      def has_artifact?(name)
        options.dig(:artifacts, :paths)&.include?(name) &&
          artifacts_metadata?
      end

      def has_security_reports?
        job_artifacts.security_reports.any?
      end

      def collect_security_reports!(security_reports, report_types: ::Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES)
        each_report(report_types) do |file_type, blob, report_artifact|
          security_reports.get_report(file_type, report_artifact).tap do |security_report|
            next unless project.feature_available?(LICENSED_PARSER_FEATURES.fetch(file_type))

            parse_security_artifact_blob(security_report, blob)
          rescue StandardError
            security_report.add_error('ParsingError')
          end
        end
      end

      def unmerged_security_reports
        security_reports = ::Gitlab::Ci::Reports::Security::Reports.new(pipeline)

        each_report(::Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES) do |file_type, blob, report_artifact|
          report = security_reports.get_report(file_type, report_artifact)
          parse_raw_security_artifact_blob(report, blob)
        end

        security_reports
      end

      def collect_license_scanning_reports!(license_scanning_report)
        return license_scanning_report unless project.feature_available?(:license_scanning)

        each_report(::Ci::JobArtifact.file_types_for_report(:license_scanning)) do |file_type, blob|
          ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, license_scanning_report)
        end

        license_scanning_report
      end

      def collect_dependency_list_reports!(dependency_list_report)
        if project.feature_available?(:dependency_scanning)
          dependency_list = ::Gitlab::Ci::Parsers::Security::DependencyList.new(project, sha, pipeline)

          each_report(::Ci::JobArtifact.file_types_for_report(:dependency_list)) do |_, blob|
            dependency_list.parse!(blob, dependency_list_report)
          end
        end

        dependency_list_report
      end

      def collect_metrics_reports!(metrics_report)
        each_report(::Ci::JobArtifact.file_types_for_report(:metrics)) do |file_type, blob|
          next unless project.feature_available?(:metrics_reports)

          ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, metrics_report)
        end

        metrics_report
      end

      def collect_requirements_reports!(requirements_report, legacy: false)
        return requirements_report unless project.feature_available?(:requirements)

        artifact_file = legacy ? :requirements : :requirements_v2

        each_report(::Ci::JobArtifact.file_types_for_report(artifact_file)) do |file_type, blob, report_artifact|
          ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, requirements_report)
        end

        requirements_report
      end

      def collect_sbom_reports!(sbom_reports_list)
        each_report(::Ci::JobArtifact.file_types_for_report(:sbom)) do |file_type, blob|
          report = ::Gitlab::Ci::Reports::Sbom::Report.new
          ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, report)
          sbom_reports_list.add_report(report)
        end
      end

      def ci_secrets_management_available?
        return false unless project

        project.feature_available?(:ci_secrets_management)
      end

      override :runner_required_feature_names
      def runner_required_feature_names
        super + ee_runner_required_feature_names
      end

      def secrets_provider?
        variable_value('VAULT_SERVER_URL').present?
      end

      def variable_value(key, default = nil)
        variables_hash.fetch(key, default)
      end

      private

      def variables_hash
        @variables_hash ||= variables.to_h do |variable|
          [variable[:key], variable[:value]]
        end
      end

      def dast_configuration_variables
        ::Gitlab::Ci::Variables::Collection.new.tap do |collection|
          break collection unless (dast_configuration = options[:dast_configuration])

          if (site_profile = dast_configuration[:site_profile] && dast_site_profile)
            collection.concat(dast_site_profile.ci_variables)
            collection.concat(dast_site_profile.secret_ci_variables(user))
          end

          if dast_configuration[:scanner_profile] && dast_scanner_profile
            collection.concat(dast_scanner_profile.ci_variables(dast_site_profile: site_profile))
          end
        end
      end

      def parse_security_artifact_blob(security_report, blob)
        report_clone = security_report.clone_as_blank
        report_clone.pipeline = pipeline # We need to set the pipeline for child pipelines
        parse_raw_security_artifact_blob(report_clone, blob)
        security_report.merge!(report_clone)
      end

      def parse_raw_security_artifact_blob(security_report, blob)
        signatures_enabled = project.licensed_feature_available?(:vulnerability_finding_signatures)
        ::Gitlab::Ci::Parsers.fabricate!(security_report.type, blob, security_report, signatures_enabled: signatures_enabled).parse!
      end

      def ee_runner_required_feature_names
        strong_memoize(:ee_runner_required_feature_names) do
          EE_RUNNER_FEATURES.select do |feature, method|
            method.call(self)
          end.keys
        end
      end

      def track_ci_secrets_management_usage
        return unless ::Feature.enabled?(:usage_data_i_ci_secrets_management_vault_build_created)

        return unless ci_secrets_management_available? && secrets?

        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event('i_ci_secrets_management_vault_build_created', values: user_id)

        return unless ::Feature.enabled?(:usage_data_i_ci_secrets_management_vault_build_created)

        ::Gitlab::Tracking.event(
          self.class.to_s,
          'create_secrets_vault',
          namespace: namespace,
          user: user,
          label: 'redis_hll_counters.ci_secrets_management.i_ci_secrets_management_vault_build_created_monthly',
          ultimate_namespace_id: namespace.root_ancestor.id,
          context: [::Gitlab::Tracking::ServicePingContext.new(
            data_source: :redis_hll,
            event: 'i_ci_secrets_management_vault_build_created'
          ).to_context]
        )
      end
    end
  end
end
