# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class CreatePipelineService < ::BaseProjectService
      def execute
        return error(s_('SecurityPolicies|Invalid or empty policy')) if ci_configs.values.all?(&:blank?)

        pipelines = {}
        error_messages = []

        if pipeline_scan_config.present?
          result = execute_pipeline_scans(pipeline_scan_config)
          pipeline_scan_pipeline = result.payload

          if pipeline_scan_pipeline.created_successfully?
            pipelines[:pipeline_scan] = pipeline_scan_pipeline
          else
            error_messages.push(pipeline_scan_pipeline.full_error_messages)
          end
        end

        if on_demand_config.present?
          result = execute_on_demand_scans(on_demand_config)

          if result.status == :success
            on_demand_pipeline = result.payload

            if on_demand_pipeline.created_successfully?
              pipelines[:on_demand] = on_demand_pipeline
            else
              error_messages.push(on_demand_pipeline.full_error_messages)
            end
          else
            error_messages.push(result.message)
          end
        end

        return error(error_messages.join(" ")) if error_messages.any?

        success(payload: pipelines)
      end

      def pipeline_scan_config
        ci_configs[:pipeline_scan]
      end

      def on_demand_config
        ci_configs[:on_demand]
      end

      private

      def ci_configs
        @ci_configs ||= prepare_ci_configurations(params[:actions])
      end

      def prepare_ci_configurations(actions)
        ::Security::SecurityOrchestrationPolicies::ScanPipelineService.new(project,
          scan_variables(actions)).execute(actions)
      end

      def scan_variables(actions)
        return {} unless actions.detect { |a| a[:scan] == 'secret_detection' }

        return { secret_detection: { 'SECRET_DETECTION_HISTORIC_SCAN' => 'true' } } unless last_scan_commit_sha.present?

        { secret_detection: { 'SECRET_DETECTION_LOG_OPTS' => commit_range } }
      end

      def pipeline_ids
        @pipeline_ids ||= Security::Scan.pipeline_ids(project, 'secret_detection')
      end

      def commit_range
        "#{last_scan_commit_sha}..#{most_recent_commit_sha}"
      end

      def last_scan_commit_sha
        @last_scan_commit_sha ||= Ci::Pipeline.order_id_desc
                                              .for_project(project).for_ref(params[:branch])
                                              .with_pipeline_source(:security_orchestration_policy)
                                              .find_by_id(pipeline_ids)&.sha
      end

      def most_recent_commit_sha
        @most_recent_commit_sha ||= project.repository.commit(params[:branch]).sha
      end

      def execute_pipeline_scans(ci_config)
        return if ci_config.blank?

        service = Ci::CreatePipelineService.new(project, current_user, ref: params[:branch])
        service.execute(:security_orchestration_policy, content: ci_config.to_yaml, variables_attributes: [])
      end

      def execute_on_demand_scans(ci_config)
        return if ci_config.blank?

        ci_config[:stages] = on_demand_stages

        service = ::AppSec::Dast::Scans::RunService.new(project, current_user)
        service.execute(branch: params[:branch], ci_configuration: ci_config.to_yaml)
      end

      def on_demand_stages
        [*Gitlab::Ci::Config::Entry::Stages.default,
         AppSec::Dast::ScanConfigs::BuildService::STAGE_NAME]
      end
    end
  end
end
