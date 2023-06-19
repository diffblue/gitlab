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

          delegate :resource, :resource=, to: :context

          def initialize(context:, options:)
            @context = context
            @options = options
            @logger = Gitlab::Llm::Logger.build
          end

          def execute
            return not_found unless authorize

            perform
          end

          def authorize
            raise NotImplementedError
          end

          def perform
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

          def not_found
            content = "I am sorry, I am unable to find the #{resource_name} you are looking for."

            Answer.error_answer(context: context, content: content)
          end

          def wrong_resource
            content = "I am sorry, I cannot proceed with this resource, it is #{resource_name}."

            Answer.error_answer(context: context, content: content)
          end
        end
      end
    end
  end
end
