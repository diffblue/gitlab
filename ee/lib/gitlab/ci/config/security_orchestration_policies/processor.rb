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
            return @config unless security_orchestration_policy_configuration&.enabled?
            return @config unless security_orchestration_policy_configuration.policy_configuration_valid?
            return @config unless extend_configuration?

            merged_config = @config
                              .deep_merge(on_demand_scans_template)
                              .deep_merge(pipeline_scan_template)
            observe_processing_duration(Time.current - @start)

            merged_config
          end

          private

          attr_reader :project

          delegate :security_orchestration_policy_configuration, to: :project, allow_nil: true

          def on_demand_scans_template
            ::Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService
              .new(project)
              .execute(security_orchestration_policy_configuration.on_demand_scan_actions(@ref))
          end

          def pipeline_scan_template
            ::Security::SecurityOrchestrationPolicies::ScanPipelineService
              .new.execute(security_orchestration_policy_configuration.pipeline_scan_actions(@ref))
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
