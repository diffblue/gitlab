# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class CiConfigurationService
      SCAN_TEMPLATES = {
        'secret_detection' => 'Jobs/Secret-Detection',
        'cluster_image_scanning' => 'Security/Cluster-Image-Scanning',
        'container_scanning' => 'Security/Container-Scanning'
      }.freeze

      def execute(action, ci_variables)
        case action[:scan]
        when 'secret_detection'
          secret_detection_configuration(ci_variables)
        when 'container_scanning', 'cluster_image_scanning'
          scan_configuration(action[:scan], ci_variables)
        else
          error_script('Invalid Scan type')
        end
      end

      private

      def scan_template(scan_type)
        template = ::TemplateFinder.build(:gitlab_ci_ymls, nil, name: SCAN_TEMPLATES[scan_type]).execute
        Gitlab::Config::Loader::Yaml.new(template.content).load!
      end

      def secret_detection_configuration(ci_variables)
        ci_configuration = scan_template('secret_detection')

        ci_configuration[:secret_detection]
          .merge(ci_configuration[:'.secret-analyzer'])
          .deep_merge(variables: ci_configuration[:variables].deep_merge(ci_variables).compact)
          .except(:extends)
      end

      def scan_configuration(template, ci_variables)
        ci_configuration = scan_template(template)

        ci_configuration[template.to_sym]
          .deep_merge(variables: ci_configuration[:variables].deep_merge(ci_variables).compact)
          .except(:rules)
      end

      def error_script(error_message)
        {
          'script' => "echo \"Error during Scan execution: #{error_message}\" && false",
          'allow_failure' => true
        }
      end
    end
  end
end
