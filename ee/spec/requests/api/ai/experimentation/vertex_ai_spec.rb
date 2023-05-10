# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ai::Experimentation::VertexAi, feature_category: :shared do
  let_it_be(:current_user) { create(:user) }
  let(:body) { { 'test' => 'test' } }
  let(:token) { create(:personal_access_token, user: current_user) }
  let(:response_double) { instance_double(HTTParty::Response, code: 200, success?: true, body: body.to_json) }
  let(:header) do
    {
      'Accept' => ['application/json'],
      'Authorization' => ["Bearer #{token}"],
      'Host' => [nil],
      'Content-Type' => ['application/json']
    }
  end

  before do
    allow_next_instance_of(Gitlab::Llm::VertexAi::Configuration) do |configuration|
      allow(configuration).to receive(:access_token).and_return(token)
    end

    stub_feature_flags(explain_vulnerability_vertex: true)
    stub_feature_flags(ai_experimentation_api: current_user)
  end

  shared_examples 'invalid request' do
    it 'returns an error' do
      post api("/ai/experimentation/tofa/#{endpoint}", current_user), params: params

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  shared_examples 'proxies request to ai api endpoint' do
    it 'responds with Workhorse send-url headers' do
      post api("/ai/experimentation/tofa/#{endpoint}", current_user), params: params

      expect(response.body).to eq('""')
      expect(response).to have_gitlab_http_status(:ok)

      send_url_prefix, encoded_data = response.headers['Gitlab-Workhorse-Send-Data'].split(':')
      data = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_data))

      expect(send_url_prefix).to eq('send-url')
      expect(data).to include({
        'AllowRedirects' => false,
        'Method' => 'POST',
        'Header' => header,
        'Body' => expected_request_body
      })
    end
  end

  describe 'POST /ai/experimentation/tofa/chat' do
    let(:endpoint) { 'chat' }
    let(:content) { 'Who won the world series in 2020?' }
    let(:context) { 'Some extra context' }
    let(:expected_messages) { [] }

    let(:examples) do
      '[{"input": {"content": "What do I like?"}, "output": {"content": "Ned likes watching movies."}}]'
    end

    let(:base_params) do
      {
        temperature: 1.0,
        max_output_tokens: 256,
        top_k: 20,
        top_p: 0.5,
        context: context,
        examples: examples
      }
    end

    let(:expected_request_body) do
      {
        instances: [{
          messages: expected_messages,
          context: context,
          examples: Gitlab::Json.parse(examples)
        }],
        parameters: {
          temperature: 1.0,
          maxOutputTokens: 256,
          topK: 20,
          topP: 0.5
        }
      }.to_json
    end

    let(:params) { base_params.merge(content: content) }

    context 'when feature flag not enabled for user' do
      let(:not_authorized_user) { create :user }
      let(:token) { create(:personal_access_token, user: not_authorized_user) }

      it 'returns not found' do
        post api("/ai/experimentation/tofa/#{endpoint}", not_authorized_user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when general feature flag not enabled' do
      before do
        stub_feature_flags(tofa_experimentation_main_flag: false)
      end

      it 'returns not found' do
        post api("/ai/experimentation/tofa/#{endpoint}", current_user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when TOFA_ACCESS_TOKEN variable is set' do
      before do
        stub_env('TOFA_ACCESS_TOKEN', 'env token')
      end

      it 'uses token from the environment variable' do
        post api("/ai/experimentation/tofa/#{endpoint}", current_user), params: params

        expect(response).to have_gitlab_http_status(:ok)

        _, encoded_data = response.headers['Gitlab-Workhorse-Send-Data'].split(':')
        data = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_data))

        expect(data['Header']['Authorization']).to eq(['Bearer env token'])
      end
    end

    context 'when neither content nor messages param is passed' do
      let(:params) { base_params }

      it_behaves_like 'invalid request'
    end

    context 'when user input can not be parsed' do
      let(:params) { base_params.merge(messages: '[{author: "user"}]') }

      it_behaves_like 'invalid request'
    end

    it_behaves_like 'proxies request to ai api endpoint' do
      let(:expected_messages) do
        [{
          author: 'user',
          content: content
        }]
      end
    end

    context 'when messages param is used' do
      let(:messages) do
        <<~STR
          [
            {"author": "user", "content": "Are my favorite movies based on a book series?"},
            {"author": "bot", "content": "Yes, your favorite movies"}
          ]
        STR
      end

      let(:params) { base_params.merge(messages: messages) }

      it_behaves_like 'proxies request to ai api endpoint' do
        let(:expected_messages) { Gitlab::Json.parse(messages) }
      end
    end
  end
end
