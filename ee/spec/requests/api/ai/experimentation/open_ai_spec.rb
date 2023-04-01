# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ai::Experimentation::OpenAi, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  let_it_be(:current_user) { create :user }
  let(:header) { { 'Authorization' => 'Bearer test-key', 'Content-Type' => 'application/json' } }
  let(:body) { { 'test' => 'test' } }
  let(:response_double) { instance_double(HTTParty::Response, code: 200, success?: true, body: body.to_json) }

  before do
    stub_application_setting(openai_api_key: 'test-key')
    stub_feature_flags(openai_experimentation: false)
    stub_feature_flags(openai_experimentation: current_user)
  end

  describe 'when feature flag not enabled for user' do
    let(:not_authorized_user) { create :user }

    [:completions, :embeddings].each do |endpoint|
      it 'returns not found' do
        post api("/ai/experimentation/openai/#{endpoint}", not_authorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /ai/experimentation/openai/completions' do
    let(:params) do
      {
        prompt: 'test',
        model: 'text-davinci-003',
        max_tokens: 16,
        stream: false,
        echo: false,
        presence_penalty: 0,
        frequency_penalty: 0,
        best_of: 1
      }
    end

    it 'calls openai endpoint' do
      expect(Gitlab::HTTP).to receive(:post).with("#{described_class::OPEN_AI_API_URL}/completions",
        headers: header,
        body: params.to_json)

      post api('/ai/experimentation/openai/completions', current_user), params: { prompt: 'test' }
    end

    it 'returns json received from openai endpoint' do
      expect(Gitlab::HTTP).to receive(:post).and_return(response_double)

      post api('/ai/experimentation/openai/completions', current_user), params: { prompt: 'test' }

      expect(json_response).to eq(body)
    end
  end

  describe 'POST /ai/experimentation/openai/embeddings' do
    let(:params) do
      {
        input: 'test',
        model: 'text-davinci-003'
      }
    end

    it 'calls openai endpoint' do
      expect(Gitlab::HTTP).to receive(:post).with("#{described_class::OPEN_AI_API_URL}/embeddings",
        headers: header,
        body: params.to_json)

      post api('/ai/experimentation/openai/embeddings', current_user), params: { input: 'test' }
    end

    it 'returns json received from openai endpoint' do
      expect(Gitlab::HTTP).to receive(:post).and_return(response_double)

      post api('/ai/experimentation/openai/embeddings', current_user), params: { input: 'test' }

      expect(json_response).to eq(body)
    end
  end
end
