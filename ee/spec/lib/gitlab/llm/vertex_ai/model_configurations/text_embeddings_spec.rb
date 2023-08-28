# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::TextEmbeddings, feature_category: :ai_abstraction_layer do
  let(:host) { 'example-env.com' }
  let(:project) { 'cllm' }

  before do
    stub_application_setting(vertex_ai_host: host)
    stub_application_setting(vertex_ai_project: project)
  end

  describe '#payload' do
    it 'returns default payload' do
      expect(subject.payload('some content')).to eq(
        {
          instances: [
            {
              content: 'some content'
            }
          ]
        }
      )
    end
  end

  describe '#url' do
    it 'returns correct url replacing default value' do
      expect(subject.url).to eq(
        'https://example-env.com/v1/projects/cllm/locations/us-central1/publishers/google/models/textembedding-gecko:predict'
      )
    end
  end
end
