# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::BaseResponseModifier, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  subject { described_class.new(response_json) }

  let(:response_json) do
    {
      "errors" => ["an error"]
    }.to_json
  end

  describe '#ai_response' do
    it 'parses the response symbolizes the keys with indifferent access' do
      expect(subject.ai_response[:errors]).to eq ["an error"]
      expect(subject.ai_response["errors"]).to eq ["an error"]
    end
  end

  describe '#response_body' do
    it 'raies NotImplementedError' do
      expect { subject.response_body }.to raise_error(NotImplementedError)
    end
  end

  describe '#errors' do
    it 'raies NotImplementedError' do
      expect { subject.errors }.to raise_error(NotImplementedError)
    end
  end
end
