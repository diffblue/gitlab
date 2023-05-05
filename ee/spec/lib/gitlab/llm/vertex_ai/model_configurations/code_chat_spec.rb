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
          parameters: Gitlab::Llm::VertexAi::Configuration.default_payload_parameters
        }
      )
    end
  end

  describe '#url' do
    it 'returns default codechat url from application settings' do
      url = 'https://example.com/api'

      stub_application_setting(tofa_url: url)

      expect(subject.url).to eq(url)
    end
  end

  describe '#host' do
    it 'returns default codechat host from application settings' do
      host = 'example.com'

      stub_application_setting(tofa_host: host)

      expect(subject.host).to eq(host)
    end
  end
end
