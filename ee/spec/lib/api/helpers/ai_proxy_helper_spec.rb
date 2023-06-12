# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::AiProxyHelper, feature_category: :application_performance do
  describe 'helper methods' do
    let(:request) { instance_double('ActionDispatch::Request') }
    let(:helper) do
      Class.new do
        def initialize(request)
          @request = request
        end

        attr_reader :request
      end.include(described_class, Grape::DSL::InsideRoute).new(request)
    end

    before do
      allow(Gitlab).to receive(:org_or_com?).and_return(is_gitlab_org_or_com)
    end

    describe '#with_proxy_ai_request' do
      context 'when on .org or .com' do
        let(:is_gitlab_org_or_com) { true }

        it 'yields the block' do
          expect { |b| helper.with_proxy_ai_request(&b) }.to yield_control
        end
      end

      context 'when not on .org and .com' do
        let(:is_gitlab_org_or_com) { false }
        let(:ai_access_token) { 'ai_access_token' }
        let(:proxy_request) { instance_double('Gitlab::SelfManaged::ProxyRequest') }

        before do
          stub_ee_application_setting(ai_access_token: ai_access_token)
        end

        it 'proxies request to saas', :aggregate_failures do
          expect(Gitlab::SelfManaged::ProxyRequest).to receive(:new)
            .with(request, ai_access_token).and_return(proxy_request)
          expect(proxy_request).to receive(:workhorse_headers)

          expect { |b| helper.with_proxy_ai_request(&b) }.not_to yield_control
        end
      end
    end
  end
end
