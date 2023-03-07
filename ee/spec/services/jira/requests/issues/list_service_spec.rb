# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Issues::ListService, feature_category: :integrations do
  include AfterNextHelpers

  let(:jira_integration) { create(:jira_integration) }
  let(:params) { {} }

  describe '#execute' do
    let(:integration) { described_class.new(jira_integration, params) }

    subject { integration.execute }

    context 'without jira_integration' do
      before do
        jira_integration.update!(active: false)
      end

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'when jira_integration is nil' do
      let(:jira_integration) { nil }

      it 'returns an error response' do
        expect(subject.error?).to be_truthy
        expect(subject.message).to eq('Jira service not configured.')
      end
    end

    context 'with jira_integration' do
      context 'when validations and params are ok' do
        let(:jira_integration) { create(:jira_integration, url: 'https://jira.example.com') }
        let(:response_body) { '' }
        let(:response_headers) { { 'content-type' => 'application/json' } }
        let(:expected_url_pattern) { %r{.*jira.example.com/rest/api/2/search.*} }

        before do
          stub_request(:get, expected_url_pattern).to_return(status: 200, body: response_body, headers: response_headers)
        end

        it_behaves_like 'a service that handles Jira API errors'

        context 'when jira runs on a subpath' do
          let(:jira_integration) { create(:jira_integration, url: 'http://jira.example.com/jira') }
          let(:expected_url_pattern) { %r{.*jira.example.com/jira/rest/api/2/search.*} }

          it 'takes the subpath into account' do
            expect(subject.success?).to be_truthy
          end
        end

        context 'when the request does not return any values' do
          let(:response_body) { [].to_json }

          it 'returns a payload with no issues' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:issues]).to be_empty
            expect(payload[:is_last]).to be_truthy
          end
        end

        context 'when the request returns values' do
          let(:response_body) do
            {
              total: 375,
              startAt: 0,
              issues: [{ key: 'TST-1' }, { key: 'TST-2' }]
            }.to_json
          end

          it 'returns a payload with jira issues' do
            payload = subject.payload

            expect(subject.success?).to be_truthy
            expect(payload[:issues].map(&:key)).to eq(%w[TST-1 TST-2])
            expect(payload[:is_last]).to be_falsy
          end
        end

        context 'when using pagination parameters' do
          let(:params) { { page: 3, per_page: 20 } }

          it 'honors page and per_page' do
            expect_next(JIRA::Client).to receive(:get).with(include('startAt=40&maxResults=20')).and_return([])

            subject
          end
        end

        context 'without pagination parameters' do
          let(:params) { {} }

          it 'uses the default options' do
            expect_next(JIRA::Client).to receive(:get).with(include('startAt=0&maxResults=100'))

            subject
          end
        end

        it 'requests for default fields' do
          expect_next(JIRA::Client).to receive(:get).with(include("fields=#{described_class::DEFAULT_FIELDS}")).and_return([])

          subject
        end
      end
    end
  end
end
