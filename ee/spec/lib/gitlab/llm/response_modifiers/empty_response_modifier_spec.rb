# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::ResponseModifiers::EmptyResponseModifier, feature_category: :gitlab_duo do # rubocop: disable RSpec/InvalidFeatureCategory
  let(:ai_response) { {} }

  it 'parses content from the ai response' do
    expect(described_class.new(ai_response).response_body).to eq('')
  end

  it 'returns empty errors' do
    expect(described_class.new(ai_response).errors).to contain_exactly('Chat not available.')
  end
end
