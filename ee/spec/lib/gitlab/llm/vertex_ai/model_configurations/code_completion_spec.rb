# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::CodeCompletion, feature_category: :shared do
  let_it_be(:host) { 'example-env.com' }
  let_it_be(:project) { 'cllm' }

  before do
    stub_application_setting(vertex_ai_host: host)
    stub_application_setting(vertex_ai_project: project)
  end

  describe '#payload' do
    it 'returns default payload' do
      messages = { prefix: 'foo', suffix: 'bar' }

      expect(subject.payload(messages)).to eq(
        {
          instances: [
            {
              prefix: 'foo',
              suffix: 'bar'
            }
          ],
          parameters: Gitlab::Llm::VertexAi::Configuration.payload_parameters(
            maxOutputTokens: Gitlab::Llm::VertexAi::ModelConfigurations::CodeCompletion::MAX_OUTPUT_TOKENS
          )
        }
      )
    end
  end

  describe '#url' do
    it 'returns correct url replacing default value' do
      expect(subject.url).to eq(
        'https://example-env.com/v1/projects/cllm/locations/us-central1/publishers/google/models/code-gecko:predict'
      )
    end
  end
end
