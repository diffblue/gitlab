# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ai::Llm::GitCommand, :saas, feature_category: :source_code_management do
  let_it_be(:current_user) { create :user }

  let(:url) { '/ai/llm/git_command' }
  let(:model) { 'vertexai' }
  let(:input_params) { { prompt: 'list 10 commit titles', model: model } }

  before do
    stub_licensed_features(ai_git_command: true)
    stub_ee_application_setting(should_check_namespace_plan: true)
  end

  describe 'POST /ai/llm/git_command', :saas, :use_clean_rails_redis_caching do
    let_it_be(:group, refind: true) { create(:group_with_plan, plan: :ultimate_plan) }

    before_all do
      group.add_developer(current_user)
    end

    include_context 'with ai features enabled for group'

    it_behaves_like 'delegates AI request to Workhorse' do
      let(:header) do
        {
          'Authorization' => ['Bearer access token'],
          'Content-Type' => ['application/json'],
          'Accept' => ["application/json"],
          'Host' => ['host']
        }
      end

      let(:expected_params) do
        expected_content = <<~PROMPT
        Provide the appropriate git commands for: list 10 commit titles.
        PROMPT

        {
          'URL' => "https://host/v1/projects/c/locations/us-central1/publishers/google/models/codechat-bison:predict",
          'Header' => header,
          'Body' => {
            instances: [{
              messages: [{
                author: "content",
                content: expected_content
              }]
            }],
            parameters: {
              temperature: 0.2,
              maxOutputTokens: 2048,
              topK: 40,
              topP: 0.95
            }
          }.to_json
        }
      end

      before do
        stub_ee_application_setting(vertex_ai_host: 'host', vertex_ai_project: 'c')

        allow_next_instance_of(::Gitlab::Llm::VertexAi::Configuration) do |instance|
          allow(instance).to receive(:access_token).and_return('access token')
        end
      end
    end

    context 'when openai model is requested' do
      let(:model) { 'openai' }
      let(:header) { { 'Authorization' => ['Bearer test-key'], 'Content-Type' => ['application/json'] } }

      before do
        stub_ee_application_setting(openai_api_key: 'test-key')
      end

      it_behaves_like 'delegates AI request to Workhorse' do
        let(:expected_params) do
          expected_content = <<~PROMPT
          Provide the appropriate git commands for: list 10 commit titles.
          Respond with JSON format
          ##
          {
            "commands": [The list of commands],
            "explanation": The explanation with the commands wrapped in backticks
          }
          PROMPT

          {
            'URL' => ::Gitlab::Llm::OpenAi::Workhorse::CHAT_URL,
            'Header' => header,
            'Body' => {
              model: 'gpt-3.5-turbo',
              messages: [{
                role: "user",
                content: expected_content
              }],
              temperature: 0.4,
              max_tokens: 200
            }.to_json
          }
        end
      end
    end

    context 'when openai experimentation is unavailable' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it 'returns bad request' do
        post api(url, current_user), params: input_params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when git command is unavailable' do
      before do
        stub_feature_flags(ai_git_command_ff: false)
      end

      it 'returns bad request' do
        post api(url, current_user), params: input_params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the endpoint is called too many times' do
      it 'returns too many requests response' do
        expect(Gitlab::ApplicationRateLimiter).to(
          receive(:throttled?).with(:ai_action, scope: [current_user]).and_return(true)
        )

        post api(url, current_user), params: input_params

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
