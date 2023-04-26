# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Completions
        class GenerateDescription
          TOTAL_MODEL_TOKEN_LIMIT = 4000

          INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.5).to_i.freeze

          INPUT_CONTENT_LIMIT = INPUT_TOKEN_LIMIT * 4

          def initialize(ai_prompt_class)
            @ai_prompt_class = ai_prompt_class
          end

          def execute(user, issuable, options)
            return unless user
            return unless issuable

            template = if options[:description_template_name].present?
                         begin
                           TemplateFinder.new(
                             :issues, issuable.project,
                             name: options[:description_template_name]
                           ).execute&.content
                         rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
                           nil
                         end
                       end

            content = <<-TEMPLATE
            Original content:
            #{options[:content]}

            Template format:
            #{template}
            TEMPLATE

            options = ai_prompt_class.get_options(content[0..INPUT_CONTENT_LIMIT])

            ai_response = Gitlab::Llm::OpenAi::Client.new(user).chat(
              content: nil,
              **options
            )

            ::Gitlab::Llm::OpenAi::ResponseService.new(user, issuable, ai_response, options: {})
              .execute(Gitlab::Llm::OpenAi::ResponseModifiers::Chat.new)
          end

          private

          attr_reader :ai_prompt_class
        end
      end
    end
  end
end
