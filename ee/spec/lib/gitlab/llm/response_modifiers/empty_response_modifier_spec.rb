# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::ResponseModifiers::EmptyResponseModifier, feature_category: :duo_chat do
  context 'when not message is passed' do
    subject(:response_modifier) { described_class.new }

    it 'parses content from the ai response' do
      expect(response_modifier.response_body).to eq('')
    end

    it 'returns empty errors' do
      expect(response_modifier.errors).to be_empty
    end
  end

  context 'when message is passed' do
    let(:message) { 'Some message' }

    subject(:response_modifier) { described_class.new(message) }

    it 'parses content from the ai response' do
      expect(response_modifier.response_body).to eq(message)
    end

    it 'returns empty errors' do
      expect(response_modifier.errors).to be_empty
    end
  end
end
