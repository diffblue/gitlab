# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module SecurityOrchestrationPolicies
        class Processor
          def initialize(config, project, ref, source)
            @config = config
            @project = project
            @ref = ref
            @source = source
            @start = Time.current
          end

          def perform
            return @config unless project&.feature_available?(:security_orchestration_policies)
            return @config if valid_security_orchestration_policy_configurations.blank?
            return @config unless extend_configuration?

            merged_config = @config
                              .deep_merge(on_demand_scans_template)
                              .deep_merge(pipeline_scan_template)

            observe_processing_duration(Time.current - @start)

            merged_config
          end

          private

          attr_reader :project

          delegate :all_security_orchestration_policy_configurations, to: :project, allow_nil: true

          def valid_security_orchestration_policy_configurations
            @valid_security_orchestration_policy_configurations ||=
              all_security_orchestration_policy_configurations&.select(&:policy_configuration_valid?)
          end

          def on_demand_scans_template
            ::Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService
              .new(project)
              .execute(on_demand_scan_actions)
          end

          def pipeline_scan_template
            ::Security::SecurityOrchestrationPolicies::ScanPipelineService
              .new.execute(pipeline_scan_actions)
          end

          def on_demand_scan_actions
            return [] if valid_security_orchestration_policy_configurations.blank?

            valid_security_orchestration_policy_configurations
              .flat_map { |security_orchestration_policy_configuration| security_orchestration_policy_configuration.on_demand_scan_actions(@ref) }
              .compact
              .uniq
          end

          def pipeline_scan_actions
            return [] if valid_security_orchestration_policy_configurations.blank?

            valid_security_orchestration_policy_configurations
              .flat_map { |security_orchestration_policy_configuration| security_orchestration_policy_configuration.pipeline_scan_actions(@ref) }
              .compact
              .uniq
          end

          def observe_processing_duration(duration)
            ::Gitlab::Ci::Pipeline::Metrics
              .pipeline_security_orchestration_policy_processing_duration_histogram
              .observe({}, duration.seconds)
          end

          def extend_configuration?
            return false if @source.nil?

            Enums::Ci::Pipeline.ci_branch_sources.key?(@source.to_sym)
          end
        end
      end
    end
  end
end
