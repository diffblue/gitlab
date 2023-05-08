# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ai::Experimentation::Anthropic, feature_category: :shared do
  let_it_be(:current_user) { create(:user) }
  let(:body) { { 'test' => 'test' } }
  let(:anthropic_api_key) { 'api-key' }
  let(:header) do
    {
      'Accept' => ['application/json'],
      'Content-Type' => ['application/json'],
      'X-Api-Key' => [anthropic_api_key]
    }
  end

  before do
    stub_application_setting(anthropic_api_key: anthropic_api_key)
  end

  describe 'POST /ai/experimentation/anthropic/complete' do
    it_behaves_like 'delegates AI request to Workhorse', :anthropic_experimentation do
      let(:input_params) do
        {
          prompt: 'Who won the world series in 2020?',
          model: 'claude-v1.3',
          max_tokens_to_sample: 256,
          stream: false,
          temperature: 1.0,
          top_k: 20.0,
          top_p: 0.5
        }
      end

      let(:url) { '/ai/experimentation/anthropic/complete' }
      let(:expected_params) do
        {
          'URL' => "#{Gitlab::Llm::Anthropic::Client::URL}/v1/complete",
          'Header' => header,
          'Body' => input_params.to_json
        }
      end
    end
  end
end
