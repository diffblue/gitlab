# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        class Tool
          include Gitlab::Utils::StrongMemoize

          NAME = 'Base Tool'
          DESCRIPTION = 'Base Tool description'
          EXAMPLE = 'Example description'
          EXAMPLE_INTRO = 'Here is an example of using this tool:'

          attr_reader :context, :options

          delegate :resource, :resource=, to: :context

          def self.full_example
            [EXAMPLE_INTRO, example].join("\n")
          end

          def self.example
            self::EXAMPLE
          end

          def initialize(context:, options:)
            @context = context
            @options = options
            @logger = Gitlab::Llm::Logger.build
          end

          def execute
            return already_used_answer if already_used?
            return not_found unless authorize

            perform
          end

          def authorize
            raise NotImplementedError
          end

          def perform
            raise NotImplementedError
          end

          def current_resource?(resource_identifier_type, resource_name)
            resource_identifier_type == 'current' && context.resource.class.name.downcase == resource_name
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

          def group_from_context
            case context.container
            when Group
              context.container
            when Project
              context.container.group
            when Namespaces::ProjectNamespace
              context.container.parent
            end
          end
          strong_memoize_attr :group_from_context

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

          def already_used_answer
            content = "You already have the answer from #{self.class::NAME} tool, read carefully."
            logger.debug(message: "Answer", class: self.class.to_s, content: content)

            ::Gitlab::Llm::Chain::Answer.new(
              status: :not_executed, context: context, content: content, tool: nil, is_final: false
            )
          end

          def already_used?
            context.tools_used.include?(self.class.name)
          end
        end
      end
    end
  end
end
