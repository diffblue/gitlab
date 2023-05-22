# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::GitlabContext, feature_category: :shared do
  # Remove this spec once actual implementation is added
  describe '#initialize' do
    it 'initializes' do
      described_class.new(current_user: nil, container: nil, resource: nil, ai_client: nil)
    end
  end
end
