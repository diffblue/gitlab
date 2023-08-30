# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::BaseResponseModifier, feature_category: :duo_chat do
  subject { described_class.new(response_json) }

  shared_examples 'handles the incoming ai_response' do
    describe '#ai_response' do
      it 'parses the response symbolizes the keys with indifferent access' do
        expect(subject.ai_response[:errors]).to eq ["an error"]
        expect(subject.ai_response["errors"]).to eq ["an error"]
      end
    end

    describe '#response_body' do
      it 'raises NotImplementedError' do
        expect { subject.response_body }.to raise_error(NotImplementedError)
      end
    end

    describe '#errors' do
      it 'raises NotImplementedError' do
        expect { subject.errors }.to raise_error(NotImplementedError)
      end
    end
  end

  context 'for parsed ai responses' do
    let(:response_json) do
      {
        "errors" => ["an error"]
      }
    end

    it_behaves_like 'handles the incoming ai_response'
  end

  context 'for unparsed ai responses' do
    let(:response_json) do
      {
        "errors" => ["an error"]
      }.to_json
    end

    it_behaves_like 'handles the incoming ai_response'
  end

  describe '#extras' do
    let(:response_json) { nil }

    it 'is empty by default' do
      expect(subject.extras).to be_nil
    end
  end
end
