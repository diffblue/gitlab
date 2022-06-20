# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::BaseUrlFinder do
  let_it_be(:provider_name) { 'Kontra' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2) }
  let_it_be(:dummy_url) { 'http://test.host/test' }
  let_it_be(:language) { "ruby" }

  describe '#execute' do
    it 'raises an error if full_url is not implemented' do
      expect { described_class.new(identifier.project, provider, identifier.external_type).execute }.to raise_error(
        NotImplementedError,
        'full_url must be overwritten to return training url'
      )
    end

    context 'when response_url is nil' do
      let_it_be(:finder) { described_class.new(identifier.project, provider, identifier.external_id) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return(nil)
        end
      end

      it 'returns a nil url with status pending' do
        expect(described_class.new(identifier.project, provider, identifier.external_id).execute).to eq({ name: provider.name, url: nil, status: 'pending' })
      end

      context 'when a language is used on the finder' do
        it 'returns a nil url with status pending' do
          expect(described_class.new(identifier.project, provider, identifier.external_id, language).execute).to eq({ name: provider.name, url: nil, status: 'pending' })
        end
      end
    end

    context 'when response_url is not nil' do
      let_it_be(:finder) { described_class.new(identifier.project, provider, identifier.external_id) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return({ url: dummy_url })
        end
      end

      it 'returns a url with status completed' do
        expect(described_class.new(identifier.project, provider, identifier.external_id).execute).to eq({ name: provider.name, url: dummy_url, status: 'completed', identifier: identifier.external_id })
      end

      context 'when a language is used on the finder' do
        it 'returns a url with status completed' do
          expect(described_class.new(identifier.project, provider, identifier.external_id, language).execute).to eq({ name: provider.name, url: dummy_url, status: 'completed', identifier: identifier.external_id })
        end
      end
    end

    context 'when response_url is not nil, but the url is' do
      let_it_be(:finder) { described_class.new(identifier.project, provider, identifier.external_id) }

      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return({ url: nil })
        end
      end

      it 'returns nil' do
        expect(described_class.new(identifier.project, provider, identifier.external_id).execute).to be_nil
      end

      context 'when a language is used on the finder' do
        it 'returns nil' do
          expect(described_class.new(identifier.project, provider, identifier.external_id, language).execute).to be_nil
        end
      end
    end
  end

  describe '.from_cache' do
    subject { described_class.from_cache("#{identifier.project.id}-#{provider.id}-#{identifier.external_id}") }

    it 'returns instance of finder object with expected attributes' do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.send(:project)).to eq(identifier.project)
      expect(subject.send(:provider)).to eq(provider)
      expect(subject.send(:identifier_external_id)).to eq(identifier.external_id)
    end

    context 'when a language is used on the finder' do
      subject { described_class.from_cache("#{identifier.project.id}-#{provider.id}-#{identifier.external_id}-#{language}") }

      it 'returns instance of finder object with expected attributes' do
        expect(subject).to be_an_instance_of(described_class)
        expect(subject.send(:project)).to eq(identifier.project)
        expect(subject.send(:provider)).to eq(provider)
        expect(subject.send(:identifier_external_id)).to eq(identifier.external_id)
        expect(subject.send(:language)).to eq(language)
      end
    end
  end

  context "private" do
    describe '#id' do
      it 'returns a cache key for ReactiveCaching specific to the request trainign urls' do
        expect(described_class.new(identifier.project, provider, identifier.external_id).send(:id)).to eq("#{identifier.project.id}-#{provider.id}-#{identifier.external_id}")
      end

      context 'when a language is used on the finder' do
        it 'returns a cache key for ReactiveCaching specific to the request trainign urls and language' do
          expect(described_class.new(identifier.project, provider, identifier.external_id, language).send(:id)).to eq("#{identifier.project.id}-#{provider.id}-#{identifier.external_id}-#{language}")
        end
      end
    end
  end
end
