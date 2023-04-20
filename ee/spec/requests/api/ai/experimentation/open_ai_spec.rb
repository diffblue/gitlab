# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ai::Experimentation::OpenAi, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  let_it_be(:current_user) { create :user }
  let(:header) { { 'Authorization' => 'Bearer test-key', 'Content-Type' => 'application/json' } }
  let(:body) { { 'test' => 'test' } }
  let(:response_double) { instance_double(HTTParty::Response, code: 200, success?: true, body: body.to_json) }

  before do
    stub_application_setting(openai_api_key: 'test-key')
    stub_feature_flags(openai_experimentation: true)
    stub_feature_flags(ai_experimentation_api: current_user)
  end

  RSpec.shared_examples 'proxies request to ai api endpoint' do
    it 'calls openai endpoint' do
      expect(Gitlab::HTTP).to receive(:post).with("#{described_class::OPEN_AI_API_URL}/#{endpoint}",
        headers: header,
        body: params.to_json,
        timeout: 90)

      post api("/ai/experimentation/openai/#{endpoint}", current_user), params: input_params
    end

    it 'returns json received from openai endpoint' do
      expect(Gitlab::HTTP).to receive(:post).and_return(response_double)

      post api("/ai/experimentation/openai/#{endpoint}", current_user), params: input_params

      expect(json_response).to eq(body)
      expect(response).to have_gitlab_http_status(:created)
    end

    context 'when request is not successful' do
      let(:response_double) { instance_double(HTTParty::Response, code: 401, success?: false, body: body.to_json) }

      it 'returns json received with status' do
        expect(Gitlab::HTTP).to receive(:post).and_return(response_double)

        post api("/ai/experimentation/openai/#{endpoint}", current_user), params: input_params

        expect(json_response).to eq(body)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when error is raised during the request' do
      it 'returns status 400' do
        expect(Gitlab::HTTP).to receive(:post).and_raise(Gitlab::HTTP::Error)

        post api("/ai/experimentation/openai/#{endpoint}", current_user), params: input_params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to include({ "message" => "Error while connecting to OpenAI: HTTParty::Error" })
      end
    end
  end

  describe 'when feature flag not enabled for user' do
    let(:not_authorized_user) { create :user }

    [:completions, :embeddings, 'chat/completions'].each do |endpoint|
      it 'returns not found' do
        post api("/ai/experimentation/openai/#{endpoint}", not_authorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'when general feature flag not enabled' do
    before do
      stub_feature_flags(openai_experimentation: false)
    end

    [:completions, :embeddings, 'chat/completions'].each do |endpoint|
      it 'returns not found' do
        post api("/ai/experimentation/openai/#{endpoint}", current_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /ai/experimentation/openai/completions' do
    it_behaves_like 'proxies request to ai api endpoint' do
      let(:input_params) { { prompt: 'test', model: 'text-davinci-003' } }
      let(:endpoint) { 'completions' }
      let(:params) do
        input_params.merge({
          temperature: 1.0,
          stream: false,
          echo: false,
          presence_penalty: 0,
          frequency_penalty: 0,
          best_of: 1
        })
      end
    end
  end

  describe 'POST /ai/experimentation/openai/embeddings' do
    it_behaves_like 'proxies request to ai api endpoint' do
      let(:input_params) { { input: 'test', model: 'text-davinci-003' } }
      let(:endpoint) { 'embeddings' }
      let(:params) do
        input_params
      end
    end
  end

  describe 'POST /ai/experimentation/openai/chat/completions' do
    it_behaves_like 'proxies request to ai api endpoint' do
      let(:messages) do
        [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: "Who won the world series in 2020?" },
          { role: "assistant", content: "The Los Angeles Dodgers won the World Series in 2020." },
          { role: "user", content: "Where was it played?" }
        ]
      end

      let(:input_params) { { messages: messages, model: 'gpt-3.5-turbo' } }
      let(:endpoint) { 'chat/completions' }
      let(:params) do
        input_params.merge({
          temperature: 1.0,
          stream: false,
          presence_penalty: 0,
          frequency_penalty: 0
        })
      end
    end
  end
end
