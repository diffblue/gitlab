# frozen_string_literal: true

module EE
  module Gitlab
    module Tracking
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :definition
        def definition(basename, category: nil, action: nil, label: nil, property: nil, value: nil, context: [], project: nil, user: nil, namespace: nil, **extra) # rubocop:disable Metrics/ParameterLists
          ee_prefix = 'ee_'
          events_path = 'config/events'

          if basename.starts_with?(ee_prefix)
            events_path = 'ee/config/events'
            basename.slice! ee_prefix
          end

          definition = YAML.load_file(Rails.root.join(*events_path, "#{basename}.yml"))

          self.dispatch_from_definition(definition, label: label, property: property, value: value, context: context,
                                                    project: project, user: user, namespace: namespace, **extra)
        end
      end
    end
  end
end
