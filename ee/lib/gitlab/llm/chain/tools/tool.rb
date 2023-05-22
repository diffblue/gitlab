# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        class Tool
          include Gitlab::Utils::StrongMemoize

          attr_reader :name, :description
          attr_accessor :context, :input_variables

          def initialize(name:, description:)
            @name = name
            @description = description
          end

          def execute(context, options)
            raise NotImplementedError
          end

          def current_resource?(resource_identifier, resource_name)
            resource_identifier == 'current' && context.resource.class.name.downcase == resource_name
          end

          def projects_from_context
            case context.container
            when Project
              [context.container]
            when Namespaces::ProjectNamespace
              [context.container.project]
            when Group
              context.container.all_projects
            end
          end
          strong_memoize_attr :projects_from_context
        end
      end
    end
  end
end
