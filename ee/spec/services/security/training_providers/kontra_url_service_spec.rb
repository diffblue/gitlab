# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::KontraUrlService, feature_category: :vulnerability_management do
  include ReactiveCachingHelpers

  let_it_be(:provider_name) { 'Kontra' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:dummy_url) { 'http://test.host/test' }

  let(:identifier_attributes) { { type: 'cwe', id: 2, name: 'cwe-2' } }
  let(:identifier_external_id) { format('[%{type}]-[%{id}]-[%{name}]', identifier_attributes) }
  let(:service) { described_class.new(project, provider, identifier_external_id) }

  describe '#calculate_reactive_cache' do
    context 'when request fails' do
      before do
        synchronous_reactive_cache(service)
        stub_request(:get, dummy_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{described_class::BEARER_TOKEN}"
            })
          .and_raise(SocketError)
      end

      it 'returns nil' do
        expect(service.calculate_reactive_cache(dummy_url)).to be_nil
      end
    end

    context 'when response is 404' do
      before do
        synchronous_reactive_cache(service)
        stub_request(:get, dummy_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{described_class::BEARER_TOKEN}"
            })
          .to_return(
            status: 404,
            body: { error: 'Exercise not found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns hash with nil url' do
        expect(service.calculate_reactive_cache(dummy_url)).to eq({ url: nil })
      end
    end

    context 'when response is not nil' do
      let_it_be(:response) { { 'link' => dummy_url } }

      before do
        synchronous_reactive_cache(service)
        stub_request(:get, dummy_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{described_class::BEARER_TOKEN}"
            })
          .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns content url hash' do
        expect(service.calculate_reactive_cache(dummy_url)).to eq({ url: dummy_url })
      end
    end

    context "when external_type is not present in allowed list" do
      let(:identifier_attributes) { { type: 'invalid type', id: 'A1', name: 'A1. Injection' } }

      it 'returns nil' do
        expect(service.execute).to be_nil
      end
    end
  end

  describe '#full_url' do
    context "when external_type is present in allowed list" do
      context "when identifier contains cwe-{number} format" do
        it 'returns full url path with proper mapping key' do
          expect(service.full_url).to eq('https://example.com?cwe=2')
        end
      end

      context "when identifier contains CWE-{number} format" do
        let(:identifier_attributes) { { type: 'CWE', id: 2, name: 'CWE-2' } }

        it 'returns full url path with proper mapping key' do
          expect(service.full_url).to eq('https://example.com?cwe=2')
        end
      end

      context "when a language is provided" do
        let_it_be(:language) { 'ruby' }

        it 'returns full url path with the language parameter mapped' do
          expect(
            described_class.new(project, provider, identifier_external_id, language).full_url
          ).to eq("https://example.com?cwe=2&language=#{language}")
        end
      end
    end

    describe '#allowed_identifier_list' do
      it 'returns allowed identifiers' do
        expect(service.allowed_identifier_list).to match_array(%w[CWE cwe])
      end
    end
  end
end
