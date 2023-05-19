# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::Tool, feature_category: :shared do
  subject(:tool) { described_class.new(name: 'Name', description: 'Description') }

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { tool.execute(nil, nil) }.to raise_error(NotImplementedError)
    end
  end
end
