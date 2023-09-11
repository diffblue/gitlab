# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrainingProviders::SecureFlagUrlFinder, feature_category: :vulnerability_management do
  include ReactiveCachingHelpers

  let_it_be(:provider_name) { 'SecureFlag' }
  let_it_be(:provider) { create(:security_training_provider, name: provider_name) }
  let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: 2, name: "cwe-2") }
  let_it_be(:dummy_url) { 'http://test.host/test' }
  let_it_be(:identifier_external_id) do
    "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]"
  end

  let(:finder) { described_class.new(identifier.project, provider, identifier_external_id) }

  describe '#calculate_reactive_cache' do
    context 'when request fails' do
      let_it_be(:finder) { described_class.new(identifier.project, provider, identifier.external_id) }

      before do
        synchronous_reactive_cache(finder)
        stub_request(:get, dummy_url).and_raise(SocketError)
      end

      it 'returns nil' do
        expect(finder.calculate_reactive_cache(dummy_url)).to be_nil
      end
    end

    context 'when response is 404' do
      before do
        synchronous_reactive_cache(finder)
        stub_request(:get, dummy_url)
          .to_return(status: 404, body: '', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns hash with nil url' do
        expect(finder.calculate_reactive_cache(dummy_url)).to eq({ url: nil })
      end
    end

    context 'when response is successful' do
      let_it_be(:response) { { 'link' => dummy_url } }

      before do
        synchronous_reactive_cache(finder)
        stub_request(:get, dummy_url)
          .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns content url hash' do
        expect(finder.calculate_reactive_cache(dummy_url)).to eq({ url: dummy_url })
      end

      context 'when response does not have a link' do
        let_it_be(:response) { nil }

        it 'returns a nil link' do
          expect(finder.calculate_reactive_cache(dummy_url)).to eq({ url: nil })
        end
      end
    end

    context "when external_type is not present in allowed list" do
      let_it_be(:identifier) do
        create(:vulnerabilities_identifier, external_type: 'invalid type', external_id: "A1", name: "A1. Injection")
      end

      let_it_be(:identifier_external_id) do
        "[#{identifier.external_type}]-[#{identifier.external_id}]-[#{identifier.name}]"
      end

      it 'returns nil' do
        expect(finder.execute).to be_nil
      end
    end
  end

  describe '#full_url' do
    context "when external_type is present in allowed list" do
      it 'returns full url path' do
        expect(finder.full_url).to eq('https://example.com?cwe=2')
      end

      context "when identifier contains CWE-{number} format" do
        let_it_be(:identifier) { create(:vulnerabilities_identifier, external_type: 'cwe', external_id: "CWE-2") }

        it 'returns full url path with proper mapping key' do
          expect(finder.full_url).to eq('https://example.com?cwe=2')
        end
      end

      context "when a language is provided" do
        let_it_be(:language) { 'ruby' }

        it 'returns full url path with the language parameter mapped' do
          expect(described_class.new(identifier.project,
            provider,
            identifier_external_id,
            language).full_url).to eq("https://example.com?cwe=2&language=#{language}")
        end
      end
    end

    describe '#allowed_identifier_list' do
      it 'returns allowed identifiers' do
        expect(finder.allowed_identifier_list).to match_array(['cwe'])
      end
    end
  end
end
