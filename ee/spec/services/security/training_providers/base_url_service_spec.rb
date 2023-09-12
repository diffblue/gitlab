# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::BaseUrlService, feature_category: :vulnerability_management do
  let_it_be(:provider_name) { 'Kontra' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2, name: 'cwe-2') }
  let_it_be(:dummy_url) { 'http://test.host/test' }
  let_it_be(:language) { "ruby" }
  let_it_be(:identifier_external_id) do
    "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]"
  end

  let(:service) { described_class.new(identifier.project, provider, identifier_external_id) }

  describe '#execute' do
    it 'raises an error if allowed_identifier_list is not implemented' do
      expect { service.execute }.to raise_error(
        'allowed_identifier_list must be overwritten to return training url'
      )
    end

    context 'when response_url is nil' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return(nil)
          allow(instance).to receive(:allowed_identifier_list).and_return(['cwe'])
        end
      end

      it 'returns a nil url with status pending' do
        expect(service.execute).to eq({ name: provider.name, url: nil, status: 'pending' })
      end

      context 'when a language is used on the service' do
        it 'returns a nil url with status pending' do
          expect(service.execute).to eq({ name: provider.name, url: nil, status: 'pending' })
        end
      end

      context "when external_type is not present in allowed list" do
        let_it_be(:identifier) do
          create(:vulnerabilities_identifier, external_type: 'owasp', external_id: "A1", name: "A1. Injection")
        end

        let_it_be(:identifier_external_id) do
          "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]"
        end

        it 'returns nil' do
          expect(service.execute).to be_nil
        end
      end
    end

    context 'when response_url is not nil' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return({ url: dummy_url })
          allow(instance).to receive(:allowed_identifier_list).and_return(%w[cwe owasp])
        end
      end

      it 'returns a url with status completed' do
        expect(service.execute).to eq({ name: provider.name, url: dummy_url, status: 'completed',
identifier: identifier.name })
      end

      context 'when a language is used on the service' do
        let(:service) { described_class.new(identifier.project, provider, identifier_external_id, language) }

        it 'returns a url with status completed' do
          expect(service.execute).to eq({ name: provider.name, url: dummy_url, status: 'completed',
identifier: identifier.name })
        end
      end
    end

    context 'when response_url is not nil, but the url is' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:response_url).and_return({ url: nil })
          allow(instance).to receive(:allowed_identifier_list).and_return(%w[cwe owasp])
        end
      end

      it 'returns nil' do
        expect(described_class.new(identifier.project, provider, identifier_external_id).execute).to be_nil
      end

      context 'when a language is used on the service' do
        let(:service) { described_class.new(identifier.project, provider, identifier_external_id, language) }

        it 'returns nil' do
          expect(service.execute).to be_nil
        end
      end
    end
  end

  describe '.from_cache' do
    subject { described_class.from_cache("#{identifier.project.id}--#{provider.id}--#{identifier.external_id}") }

    it 'returns instance of service object with expected attributes' do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.send(:project)).to eq(identifier.project)
      expect(subject.send(:provider)).to eq(provider)
      expect(subject.send(:identifier_external_id)).to eq(identifier.external_id)
    end

    context 'when a language is used on the service' do
      subject do
        described_class.from_cache("#{identifier.project.id}--#{provider.id}--#{identifier_external_id}--#{language}")
      end

      it 'returns instance of service object with expected attributes' do
        expect(subject).to be_an_instance_of(described_class)
        expect(subject.send(:project)).to eq(identifier.project)
        expect(subject.send(:provider)).to eq(provider)
        expect(subject.send(:identifier_external_id)).to eq(identifier_external_id)
        expect(subject.send(:language)).to eq(language)
      end
    end
  end

  describe '#full_url' do
    let(:implementation) do
      Class.new(described_class) do
        def query_params
          {
            a: '?',
            b: '123',
            c: 'a=c&b'
          }
        end
      end
    end

    subject(:service) { implementation.new(identifier.project, provider, identifier_external_id) }

    it 'returns provider url with encoded query params' do
      expect(service.full_url).to eq("#{provider.url}?a=%3F&b=123&c=a%3Dc%26b")
    end

    context 'when query_params is not implemented' do
      let(:implementation) { described_class }

      it 'returns the provider url' do
        expect(service.full_url).to eq(provider.url)
      end
    end
  end

  describe "private methods" do
    describe '#id' do
      it 'returns a cache key for ReactiveCaching specific to the request trainign urls' do
        expect(service.send(:id))
          .to eq("#{identifier.project.id}--#{provider.id}--#{identifier_external_id}")
      end

      context 'when a language is used on the service' do
        it 'returns a cache key for ReactiveCaching specific to the request trainign urls and language' do
          expect(described_class.new(identifier.project, provider, identifier_external_id, language).send(:id))
            .to eq("#{identifier.project.id}--#{provider.id}--#{identifier_external_id}--#{language}")
        end
      end
    end
  end
end
