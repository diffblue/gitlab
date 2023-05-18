# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot, feature_category: :shared do
  # Remove this spec once actual implementation is added
  describe '#initialize' do
    it 'initializes' do
      described_class.new(tools: nil, input_prompt: nil)
    end
  end
end
