# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        class Identifier < Tool
          include Concerns::AiDependent

          attr_accessor :retries

          MAX_RETRIES = 3

          def initialize(context:, options:)
            super
            @retries = 0
          end

          def perform
            MAX_RETRIES.times do
              json = extract_json(request)
              resource = identify_resource(json[:ResourceIdentifierType], json[:ResourceIdentifier])

              # if resource not found then return an error as the answer.
              logger.error(message: "Error finding #{resource_name}", content: json) unless resource
              return not_found unless resource

              # now the resource in context is being referenced in user input.
              context.resource = resource
              content = "I identified the #{resource_name} #{json[:ResourceIdentifier]}."
              content += " For more information use ResourceReader." if load_json?

              logger.debug(message: "Answer", class: self.class.to_s, content: content)
              return Answer.new(status: :ok, context: context, content: content, tool: nil)
            rescue JSON::ParserError
              error_message = "\nObservation: JSON has an invalid format. Please retry"
              logger.error(message: "Error", class: self.class.to_s, error: error_message)

              options[:suggestions] += error_message
            rescue StandardError => e
              logger.error(message: "Error", error: e.message, class: self.class.to_s)
              return Answer.error_answer(context: context, content: _("Unexpected error"))
            end

            not_found
          end

          private

          def resource_name
            raise NotImplementedError
          end

          def reference_pattern_by_type
            raise NotImplementedError
          end

          def prompt_template
            raise NotImplementedError
          end

          def by_iid
            raise NotImplementedError
          end

          def extract_resource
            raise NotImplementedError
          end

          def load_json?
            Feature.enabled?(:push_ai_to_load_identified_issue_json)
          end

          def authorize
            Utils::Authorizer.context_authorized?(context: context)
          end

          def identify_resource(resource_identifier_type, resource_identifier)
            return context.resource if current_resource?(resource_identifier_type, resource_name)

            resource = case resource_identifier_type
                       when 'iid'
                         by_iid(resource_identifier)
                       when 'url', 'reference'
                         extract_resource(resource_identifier, resource_identifier_type)
                       end

            resource if Utils::Authorizer.resource_authorized?(resource: resource, user: context.current_user)
          end

          def extract_json(response)
            response = "```json
                  \{
                    \"ResourceIdentifierType\": \"" + response
            response = (Utils::TextProcessing.text_before_stop_word(response, /Question:/) || response).to_s.strip
            content_after_ticks = response.split(/```json/, 2).last
            content_between_ticks = content_after_ticks&.split(/```/, 2)&.first

            Gitlab::Json.parse(content_between_ticks&.strip.to_s).with_indifferent_access
          end

          def already_used_answer
            resource = context.resource
            content = "You already have identified the #{resource_name} #{resource.to_global_id}, read carefully."
            logger.debug(message: "Answer", class: self.class.to_s, content: content)

            ::Gitlab::Llm::Chain::Answer.new(
              status: :not_executed, context: context, content: content, tool: nil, is_final: false
            )
          end

          # This method should not be memoized because the options change each iteration, e.g options[:suggestions]
          def base_prompt
            Utils::Prompt.no_role_text(prompt_template, options)
          end

          def extract_project(text, type)
            return projects_from_context.first unless projects_from_context.blank?

            project_path = text.match(reference_pattern_by_type[type])&.values_at(:namespace, :project)
            context.current_user.authorized_projects.find_by_full_path(project_path.join('/')) if project_path
          end
        end
      end
    end
  end
end
