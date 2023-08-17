# frozen_string_literal: true

module API
  module Ai
    module Llm
      class GitCommand < ::API::Base
        feature_category :source_code_management
        urgency :low

        helpers ::API::Helpers::AiHelper

        before do
          authenticate!
          check_rate_limit!(:ai_action, scope: [current_user])
        end

        namespace 'ai/llm' do
          desc 'Asks OpenAI to generate Git command from natural text'
          params do
            requires :prompt, type: String
            optional :model,
              type: String,
              values: [::Llm::GitCommandService::OPENAI, ::Llm::GitCommandService::VERTEXAI],
              default: 'openai'
          end
          post 'git_command' do
            response = ::Llm::GitCommandService.new(current_user, current_user, declared_params).execute

            if response.success?
              workhorse_headers =
                if declared_params[:model] == ::Llm::GitCommandService::VERTEXAI
                  config = response.payload
                  Gitlab::Workhorse.send_url(
                    config[:url],
                    body: config[:body],
                    headers: config[:headers].transform_values { |v| [v] },
                    method: "POST"
                  )
                else
                  ::Gitlab::Llm::OpenAi::Workhorse.chat_response(options: response.payload)
                end

              header(*workhorse_headers)
              status :ok
              body ''
            else
              bad_request!(response.message)
            end
          end
        end
      end
    end
  end
end
