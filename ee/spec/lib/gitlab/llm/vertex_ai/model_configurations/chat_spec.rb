# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ModelConfigurations::Chat, feature_category: :shared do
  let_it_be(:host) { 'example-env.com' }
  let_it_be(:project) { 'cllm' }

  before do
    stub_application_setting(tofa_host: host)
    stub_application_setting(vertex_project: project)
  end

  describe '#payload' do
    it 'returns default payload' do
      messages = [
        { author: 'user', content: 'foo' },
        { author: 'content', content: 'bar' },
        { author: 'user', content: 'baz' }
      ]

      expect(subject.payload(messages)).to eq(
        {
          instances: [
            {
              messages: messages
            }
          ],
          parameters: Gitlab::Llm::VertexAi::Configuration.default_payload_parameters
        }
      )
    end
  end

  describe '#url' do
    it 'returns correct url replacing default value' do
      expect(subject.url).to eq(
        'https://example-env.com/v1/projects/cllm/locations/us-central1/publishers/google/models/chat-bison:predict'
      )
    end
  end
end
