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
          check_feature_enabled!
        end

        namespace 'ai/llm' do
          desc 'Asks OpenAI to generate Git command from natural text'
          params do
            requires :prompt, type: String
          end
          post 'git_command' do
            response = ::Llm::GitCommandService.new(current_user, current_user, declared_params).execute

            if response.success?
              workhorse_headers = ::Gitlab::Llm::OpenAi::Workhorse.chat_response(options: response.payload)

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
