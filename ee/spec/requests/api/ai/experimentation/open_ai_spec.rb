# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ai::Experimentation::OpenAi, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  let_it_be(:current_user) { create :user }
  let(:header) { { 'Authorization' => ['Bearer test-key'], 'Content-Type' => ['application/json'] } }
  let(:body) { { 'test' => 'test' } }

  before do
    stub_application_setting(openai_api_key: 'test-key')
    stub_feature_flags(openai_experimentation: true)
    stub_feature_flags(ai_experimentation_api: current_user)
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
    it_behaves_like 'delegates AI request to Workhorse', :openai_experimentation do
      let(:input_params) { { prompt: 'test', model: 'text-davinci-003' } }
      let(:url) { '/ai/experimentation/openai/completions' }
      let(:expected_params) do
        {
          'URL' => "#{described_class::OPEN_AI_API_URL}/completions",
          'Header' => header,
          'Body' => input_params.merge({
            temperature: 1.0,
            stream: false,
            echo: false,
            presence_penalty: 0,
            frequency_penalty: 0,
            best_of: 1
          }).to_json
        }
      end
    end
  end

  describe 'POST /ai/experimentation/openai/embeddings' do
    it_behaves_like 'delegates AI request to Workhorse', :openai_experimentation do
      let(:input_params) { { input: 'test', model: 'text-davinci-003' } }
      let(:url) { '/ai/experimentation/openai/embeddings' }
      let(:expected_params) do
        {
          'URL' => "#{described_class::OPEN_AI_API_URL}/embeddings",
          'Header' => header,
          'Body' => input_params.to_json
        }
      end
    end
  end

  describe 'POST /ai/experimentation/openai/chat/completions' do
    it_behaves_like 'delegates AI request to Workhorse', :openai_experimentation do
      let(:messages) do
        [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: "Who won the world series in 2020?" },
          { role: "assistant", content: "The Los Angeles Dodgers won the World Series in 2020." },
          { role: "user", content: "Where was it played?" }
        ]
      end

      let(:input_params) { { messages: messages, model: 'gpt-3.5-turbo' } }
      let(:url) { '/ai/experimentation/openai/chat/completions' }
      let(:expected_params) do
        {
          'URL' => "#{described_class::OPEN_AI_API_URL}/chat/completions",
          'Header' => header,
          'Body' => input_params.merge({
            temperature: 1.0,
            stream: false,
            presence_penalty: 0,
            frequency_penalty: 0
          }).to_json
        }
      end
    end
  end
end
