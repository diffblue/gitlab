# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::ResponseModifiers::Completions, feature_category: :ai_abstraction_layer do
  let(:ai_response) { { choices: [{ text: 'hello' }] }.to_json }

  it 'parses content from the ai response' do
    expect(described_class.new(ai_response).response_body).to eq('hello')
  end
end
