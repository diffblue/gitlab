# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Parsers::OutputParser, feature_category: :duo_chat do
  subject(:parser) { described_class.new(output: nil) }

  describe '#parse' do
    it 'raises' do
      expect { subject.parse }.to raise_error(NotImplementedError)
    end
  end
end
