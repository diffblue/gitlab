# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class LegacyCiConfigurationService
      SCAN_TEMPLATES = {
        'secret_detection' => 'Jobs/Secret-Detection',
        'container_scanning' => 'Jobs/Container-Scanning',
        'sast' => 'Security/SAST',
        'dependency_scanning' => 'Jobs/Dependency-Scanning'
      }.freeze

      def execute(action, ci_variables)
        case action[:scan]
        when 'secret_detection'
          secret_detection_configuration(action, ci_variables)
        when 'container_scanning'
          scan_configuration(action, ci_variables)
        when 'sast'
          child_pipeline_configuration(action, ci_variables)
        when 'dependency_scanning'
          child_pipeline_configuration(action, ci_variables)
        else
          error_script('Invalid Scan type')
        end
      end

      private

      def scan_template(scan_type)
        template = ::TemplateFinder.build(:gitlab_ci_ymls, nil, name: SCAN_TEMPLATES[scan_type]).execute
        Gitlab::Config::Loader::Yaml.new(template.content).load!
      end

      def secret_detection_configuration(action, ci_variables)
        tags = action[:tags]
        ci_configuration = scan_template('secret_detection')

        ci_configuration[:secret_detection]
          .merge(tags ? { tags: tags } : {})
          .merge(ci_configuration[:'.secret-analyzer'])
          .deep_merge(variables: ci_configuration[:variables].deep_merge(ci_variables).compact)
          .except(:extends)
      end

      def scan_configuration(action, ci_variables)
        template = action[:scan]
        tags = action[:tags]
        ci_configuration = scan_template(template)

        ci_configuration[template.to_sym]
          .merge(tags ? { tags: tags } : {})
          .deep_merge(variables: ci_configuration[:variables].deep_merge(ci_variables).compact)
      end

      def child_pipeline_configuration(action, ci_variables)
        template = action[:scan]
        {
          variables: ci_variables.compact.presence,
          inherit: {
            variables: false
          },
          trigger: {
            include: [{ template: "#{SCAN_TEMPLATES[template.to_s]}.gitlab-ci.yml" }]
          }
        }.compact
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
