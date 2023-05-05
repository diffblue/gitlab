# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::Text, feature_category: :shared do
  let_it_be(:url) { 'https://example-preprod-env.com/endpoints/codechat-bison-001:predict' }

  before do
    stub_application_setting(tofa_url: url)
  end

  describe '#payload' do
    it 'returns default payload' do
      expect(subject.payload('foo')).to eq(
        {
          instances: [
            {
              content: 'foo'
            }
          ],
          parameters: Gitlab::Llm::VertexAi::Configuration.default_payload_parameters
        }
      )
    end
  end

  describe '#url' do
    it 'returns correct url replacing default value' do
      expect(subject.url).to eq('https://example-env.com/publishers/google/models/text-bison:predict')
    end
  end

  describe '#host' do
    it 'returns correct host replacing default value' do
      expect(subject.host).to eq('example-env.com')
    end
  end
end
