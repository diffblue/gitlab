# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Prompts::CodeCompletion::VertexAi, feature_category: :code_suggestions do
  subject { described_class.new({}) }

  describe '#request_params' do
    it 'returns expected request params' do
      request_params = { prompt_version: 1 }

      expect(subject.request_params).to eq(request_params)
    end
  end
end
