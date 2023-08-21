# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Required
        class Processor
          RequiredError = Class.new(StandardError)

          def initialize(config)
            @config = config
          end

          def perform
            return @config unless ::License.feature_available?(:required_ci_templates)
            return @config unless required_ci_template_name.present?

            merge_required_template
          end

          def merge_required_template
            raise RequiredError, "Required template '#{required_ci_template_name}' not found!" unless required_template

            @config.deep_merge(required_template_hash)
          end

          private

          def required_template_hash
            ci_yaml = Gitlab::Ci::Config::Yaml::Loader.new(required_template.content).load

            ci_yaml.content
          end

          def required_template
            ::TemplateFinder.build(:gitlab_ci_ymls, nil, name: required_ci_template_name).execute
          end

          def required_ci_template_name
            ::Gitlab::CurrentSettings.current_application_settings.required_instance_ci_template
          end
        end
      end
    end
  end
end
