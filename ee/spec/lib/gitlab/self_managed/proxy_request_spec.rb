# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SelfManaged::ProxyRequest, feature_category: :application_performance do
  describe '#workhorse_headers' do
    let(:request) { instance_double('ActionDispatch::Request') }
    let(:request_path) { '/api/v4/api_call' }
    let(:ai_access_token) { 'ai_access_token' }
    let(:proxy_request) { described_class.new(request, ai_access_token) }
    let(:request_method) { 'POST' }
    let(:expected_headers) do
      {
        "Authorization" => ["Bearer #{ai_access_token}"],
        "Content-Type" => ["application/json"]
      }
    end

    shared_examples 'proxy call with workhorse send_url' do
      it 'proxy call to saas url using workhorse send_url' do
        expect(Gitlab::Workhorse).to receive(:send_url)
          .with(expected_url, headers: expected_headers, method: request.request_method)

        proxy_request.workhorse_headers
      end
    end

    before do
      allow(request).to receive(:path).and_return(request_path)
      allow(request).to receive(:request_method).and_return(request_method)
    end

    context 'when GITLAB_SAAS_URL is set' do
      let(:saas_url_env) { 'https://example.gitlab.org' }
      let(:expected_url) { "#{saas_url_env}#{request_path}" }

      before do
        stub_env('GITLAB_SAAS_URL', saas_url_env)
      end

      include_examples 'proxy call with workhorse send_url'
    end

    context 'when GITLAB_SAAS_URL is not set' do
      let(:expected_url) { "#{Gitlab::Saas.com_url}#{request_path}" }

      include_examples 'proxy call with workhorse send_url'
    end
  end
end
