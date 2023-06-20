# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::CodeChat, feature_category: :shared do
  describe '#payload' do
    it 'returns default payload' do
      expect(subject.payload('foo')).to eq(
        {
          instances: [
            {
              messages: [
                {
                  author: 'content',
                  content: 'foo'
                }
              ]
            }
          ],
          parameters: Gitlab::Llm::VertexAi::Configuration.payload_parameters(
            maxOutputTokens: Gitlab::Llm::VertexAi::ModelConfigurations::CodeChat::MAX_OUTPUT_TOKENS
          )
        }
      )
    end
  end

  describe '#url' do
    it 'returns default codechat url from application settings' do
      host = 'example.com'
      project = 'llm'

      stub_application_setting(vertex_ai_host: host)
      stub_application_setting(vertex_ai_project: project)

      expect(subject.url).to eq(
        'https://example.com/v1/projects/llm/locations/us-central1/publishers/google/models/codechat-bison:predict'
      )
    end
  end
end
