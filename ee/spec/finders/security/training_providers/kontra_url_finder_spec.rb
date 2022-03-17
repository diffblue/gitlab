# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::KontraUrlFinder do
  include ReactiveCachingHelpers

  let_it_be(:provider_name) { 'Kontra' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2) }
  let_it_be(:dummy_url) { 'http://test.host/test' }

  describe '#calculate_reactive_cache' do
    context 'when response is nil' do
      let_it_be(:finder) {described_class.new(identifier.project, provider, identifier.external_id) }

      before do
        synchronous_reactive_cache(finder)
        allow(Gitlab::HTTP).to receive(:try_get).and_return(nil)
      end

      it 'returns nil' do
        expect(finder.calculate_reactive_cache(dummy_url)).to be_nil
      end
    end

    context 'when response is not nil' do
      let_it_be(:finder) { described_class.new(identifier.project, provider, identifier.external_id) }
      let_it_be(:response) { { 'link' => dummy_url } }

      before do
        synchronous_reactive_cache(finder)
        allow(Gitlab::HTTP).to receive_message_chain(:try_get, :parsed_response).and_return(response)
      end

      it 'returns content url hash' do
        expect(finder.calculate_reactive_cache(dummy_url)).to eq({ url: dummy_url })
      end
    end
  end

  describe '#full_url' do
    it 'returns full url path' do
      expect(described_class.new(identifier.project, provider, identifier.external_id).full_url).to eq('example.com/?cwe=2')
    end
  end
end
