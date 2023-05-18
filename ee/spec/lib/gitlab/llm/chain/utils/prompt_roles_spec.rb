# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Utils::PromptRoles, feature_category: :shared do
  # Remove this spec once actual implementation is added
  describe '#initialize' do
    it 'initializes' do
      described_class.new
    end
  end
end
