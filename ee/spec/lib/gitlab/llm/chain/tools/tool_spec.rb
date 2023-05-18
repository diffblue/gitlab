# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::Tool, feature_category: :shared do
  # Remove this spec once actual implementation is added
  describe '#initialize' do
    it 'initializes' do
      described_class.new(name: nil, description: nil)
    end
  end
end
