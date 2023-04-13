# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::ResponseModifiers::Completions, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  it 'parses content from the ai response' do
    expect(described_class.new.execute({ choices: [{ text: 'hello' }] })).to eq('hello')
  end
end
