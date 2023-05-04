# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class OnDemandScanPipelineConfigurationService
      include Gitlab::Utils::StrongMemoize

      def initialize(project)
        @project = project
      end

      def execute(actions)
        ci_configs(actions).reduce({}, :merge)
      end

      private

      DAST_ON_DEMAND_TEMPLATE_NAME = 'DAST-On-Demand-Scan'

      attr_reader :project

      def ci_configs(actions)
        actions.map.with_index { |action, index| prepare_policy_configuration(action, index) }
      end

      def prepare_policy_configuration(action, index)
        {
          "dast-on-demand-#{index}" => prepare_on_demand_scan_configuration(action)
        }.deep_symbolize_keys
      end

      def prepare_on_demand_scan_configuration(action)
        result = prepare_base_configuration(action[:site_profile], action[:scanner_profile])
        return error_script(result.message) unless result.success?

        action_variables = action[:variables].to_h.stringify_keys
        ci_configuration = YAML.safe_load(result.payload[:ci_configuration])

        dast_on_demand_template[:dast]
          .merge(action[:tags] ? { tags: action[:tags] } : {})
          .deep_merge(
            'stage' => 'dast',
            'variables' => dast_on_demand_variables(action_variables),
            'dast_configuration' => ci_configuration['dast']['dast_configuration']
          )
      end

      def prepare_base_configuration(site_profile_name, scanner_profile_name)
        site_profile = DastSiteProfilesFinder.new(project_id: project.id, name: site_profile_name).execute.first
        scanner_profile = DastScannerProfilesFinder.new(project_ids: [project.id], name: scanner_profile_name).execute.first if scanner_profile_name.present?

        AppSec::Dast::ScanConfigs::BuildService
          .new(container: project, params: { dast_site_profile: site_profile, dast_scanner_profile: scanner_profile })
          .execute
      end

      def dast_on_demand_template
        strong_memoize(:dast_on_demand_template) do
          template = ::TemplateFinder.build(:gitlab_ci_ymls, nil, name: DAST_ON_DEMAND_TEMPLATE_NAME).execute
          Gitlab::Ci::Config::Yaml.load!(template.content)
        end
      end

      def dast_on_demand_variables(action_variables)
        dast_on_demand_template[:variables]
          .merge(dast_on_demand_template[:dast][:variables])
          .merge(action_variables)
      end

      def error_script(error_message)
        {
          'script' => "echo \"Error during On-Demand Scan execution: #{error_message}\" && false",
          'allow_failure' => true
        }
      end
    end
  end
end
