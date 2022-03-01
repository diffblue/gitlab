# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::BaseUrlFinder do
  let_it_be(:provider_name) { 'Kontra' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2) }
  let_it_be(:dummy_url) { 'http://test.host/test' }

  describe '#execute' do
    it 'raises an error if full_url is not implemented' do
      expect { described_class.new(nil, nil).execute }.to raise_error(
        NotImplementedError,
        'full_url must be overwritten to return training url'
      )
    end

    context 'when response_url is nil' do
      let_it_be(:finder) { described_class.new(provider, identifier) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return(nil)
        end
      end

      it 'returns a nil url with status pending' do
        expect(described_class.new(provider, identifier).execute).to eq({ name: provider.name, url: nil, status: 'pending' })
      end
    end

    context 'when response_url is not nil' do
      let_it_be(:finder) { described_class.new(provider, identifier) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return({ url: dummy_url })
        end
      end

      it 'returns a url with status completed' do
        expect(described_class.new(provider, identifier).execute).to eq({ name: provider.name, url: dummy_url, status: 'completed' })
      end
    end

    context 'when response_url is not nil, but the url is' do
      let_it_be(:finder) { described_class.new(provider, identifier) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return({ url: nil })
        end
      end

      it 'returns nil' do
        expect(described_class.new(provider, identifier).execute).to be_nil
      end
    end
  end

  describe '.from_cache' do
    it 'returns instance of finder object' do
      expect(described_class.from_cache("#{identifier.project.id}-#{provider.id}-#{identifier.id}")).to be_an_instance_of(described_class)
    end
  end
end
