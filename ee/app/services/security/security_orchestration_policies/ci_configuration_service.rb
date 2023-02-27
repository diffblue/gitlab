# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class CiConfigurationService
      SCAN_TEMPLATES = {
        'secret_detection' => 'Jobs/Secret-Detection',
        'container_scanning' => 'Jobs/Container-Scanning',
        'sast' => 'Jobs/SAST',
        'sast_iac' => 'Jobs/SAST-IaC',
        'dependency_scanning' => 'Jobs/Dependency-Scanning'
      }.freeze

      def execute(action, ci_variables, index = 0)
        case action[:scan]
        when *SCAN_TEMPLATES.keys
          pipeline_configuration(action, ci_variables, index)
        else
          error_script('Invalid Scan type', action, index)
        end
      end

      private

      def scan_template(scan_type)
        template = ::TemplateFinder.build(:gitlab_ci_ymls, nil, name: SCAN_TEMPLATES[scan_type]).execute
        Gitlab::Ci::Config.new(template.content).to_hash
      end

      def pipeline_configuration(action, ci_variables, index)
        scan_type = action[:scan]
        ci_configuration = scan_template(scan_type)
        variables = merge_variables(ci_configuration.delete(:variables), ci_variables)

        ci_configuration.reject! { |job_name, _| hidden_job?(job_name) }
        ci_configuration.transform_keys! { |job_name| generate_job_name_with_index(job_name, index) }

        ci_configuration.each do |_, job_configuration|
          apply_variables!(job_configuration, variables)
          apply_tags!(job_configuration, action[:tags])
          remove_extends!(job_configuration)
          remove_rule_to_disable_job!(job_configuration)
        end

        ci_configuration
      end

      def error_script(error_message, action, index)
        {
          generate_job_name_with_index(action[:scan], index) => {
            'script' => "echo \"Error during Scan execution: #{error_message}\" && false",
            'allow_failure' => true
          }
        }
      end

      def hidden_job?(job_name)
        job_name.start_with?('.')
      end

      def generate_job_name_with_index(job_name, index)
        "#{job_name.to_s.dasherize}-#{index}".to_sym
      end

      def apply_variables!(job_configuration, variables)
        job_configuration[:variables] = merge_variables(job_configuration[:variables], variables)
      end

      def merge_variables(template_variables, variables)
        template_variables.to_h.stringify_keys.deep_merge(variables).compact
      end

      def apply_tags!(job_configuration, tags)
        return if tags.blank?

        job_configuration[:tags] = tags
      end

      def remove_extends!(job_configuration)
        job_configuration.delete(:extends)
      end

      def remove_rule_to_disable_job!(job_configuration)
        job_configuration[:rules]&.reject! { |rule| rule[:if]&.include?('_DISABLED') }
      end
    end
  end
end
