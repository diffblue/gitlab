# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        class Tool
          include Gitlab::Utils::StrongMemoize

          NAME = 'Base Tool'
          DESCRIPTION = 'Base Tool description'

          attr_reader :context, :options

          delegate :resource, to: :context

          def initialize(context:, options:)
            @context = context
            @options = options
            @logger = Gitlab::Llm::Logger.build
          end

          def execute
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

          private

          attr_reader :logger
        end
      end
    end
  end
end
