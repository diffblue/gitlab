# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module SecurityOrchestrationPolicies
        class Processor
          DEFAULT_ON_DEMAND_STAGE = 'dast'
          DEFAULT_SECURITY_JOB_STAGE = 'test'

          DEFAULT_BUILD_STAGE = 'build'
          DEFAULT_SCAN_POLICY_STAGE = 'scan-policies'
          DEFAULT_STAGES = Gitlab::Ci::Config::Entry::Stages.default

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

            merged_config = @config.deep_merge(merge_policies_with_stages(@config))

            observe_processing_duration(Time.current - @start)

            merged_config
          end

          private

          attr_reader :project

          def valid_security_orchestration_policy_configurations
            @valid_security_orchestration_policy_configurations ||= project.all_security_orchestration_policy_configurations
          end

          def prepare_on_demand_scans_template
            scan_templates[:on_demand]
          end

          def prepare_pipeline_scans_template
            scan_templates[:pipeline_scan]
          end

          def scan_templates
            @scan_templates ||= ::Security::SecurityOrchestrationPolicies::ScanPipelineService.new(project).execute(active_scan_actions)
          end

          ## Add `dast` to the end of stages if `dast` is not in stages already
          ## For other scan types, add `scan-policies` stage after `build` stage if `test` stage is not defined
          def merge_policies_with_stages(config)
            merged_config = config
            defined_stages = config[:stages].presence || DEFAULT_STAGES.clone

            merge_on_demand_scan_template(merged_config, defined_stages)
            merge_pipeline_scan_template(merged_config, defined_stages)

            merged_config[:stages] = defined_stages.uniq if (defined_stages - DEFAULT_STAGES).present?

            merged_config
          end

          def merge_on_demand_scan_template(merged_config, defined_stages)
            on_demand_scan_template = prepare_on_demand_scans_template
            on_demand_scan_job_names = on_demand_scan_template.keys

            if on_demand_scan_template.present?
              defined_stages << DEFAULT_ON_DEMAND_STAGE
              merged_config.except!(*on_demand_scan_job_names).deep_merge!(on_demand_scan_template)
            end
          end

          def merge_pipeline_scan_template(merged_config, defined_stages)
            pipeline_scan_template = prepare_pipeline_scans_template
            pipeline_scan_job_names = prepare_pipeline_scans_template.keys

            if pipeline_scan_template.present?
              unless defined_stages.include?(DEFAULT_SECURITY_JOB_STAGE)
                insert_scan_policy_stage_after_build_stage_or_first(defined_stages)
                pipeline_scan_template = pipeline_scan_template.transform_values { |job_config| job_config.merge(stage: DEFAULT_SCAN_POLICY_STAGE) }
              end

              merged_config.except!(*pipeline_scan_job_names).deep_merge!(pipeline_scan_template)
            end
          end

          def insert_scan_policy_stage_after_build_stage_or_first(defined_stages)
            build_stage_index = defined_stages.index(DEFAULT_BUILD_STAGE)
            if build_stage_index.nil?
              defined_stages.unshift(DEFAULT_SCAN_POLICY_STAGE)
            else
              defined_stages.insert(build_stage_index + 1, DEFAULT_SCAN_POLICY_STAGE)
            end

            defined_stages
          end

          def active_scan_actions
            scan_actions do |configuration|
              configuration.active_policies_scan_actions(@ref)
            end
          end

          def scan_actions
            return [] if valid_security_orchestration_policy_configurations.blank?

            valid_security_orchestration_policy_configurations
              .flat_map { |security_orchestration_policy_configuration| yield(security_orchestration_policy_configuration) }
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

            Enums::Ci::Pipeline.ci_sources.key?(@source.to_sym)
          end
        end
      end
    end
  end
end
