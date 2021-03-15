# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ManuallyCreateService do
  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests

  subject { described_class.new(project, user, params: params).execute }

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(create_vulnerabilities_via_api: false)
      end

      let(:scanner_params) do
        {
          name: "My manual scanner"
        }
      end

      let(:identifier_params) do
        {
          name: "Test identifier 1",
          url: "https://test.com"
        }
      end

      let(:params) do
        {
          vulnerability: {
            title: "Test vulnerability",
            state: "detected",
            severity: "unknown",
            confidence: "unknown",
            identifiers: [identifier_params],
            scanner: scanner_params
          }
        }
      end

      it 'returns an error' do
        result = subject
        expect(result.success?).to be_falsey
        expect(subject.message).to match(/create_vulnerabilities_via_api feature flag is not enabled for this project/)
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(create_vulnerabilities_via_api: project)
      end

      context 'with valid parameters' do
        let(:scanner_params) do
          {
            name: "My manual scanner"
          }
        end

        let(:identifier_params) do
          {
            name: "Test identifier 1",
            url: "https://test.com"
          }
        end

        let(:params) do
          {
            vulnerability: {
              title: "Test vulnerability",
              state: "detected",
              severity: "unknown",
              confidence: "unknown",
              identifiers: [identifier_params],
              scanner: scanner_params
            }
          }
        end

        let(:vulnerability) { subject.payload[:vulnerability] }

        it 'does not exceed query limit' do
          expect { subject }.not_to exceed_query_limit(20)
        end

        it 'creates a new Vulnerability' do
          expect { subject }.to change(Vulnerability, :count).by(1)
        end

        it 'creates a Vulnerability with correct attributes' do
          expect(vulnerability.report_type).to eq("generic")
          expect(vulnerability.state).to eq(params.dig(:vulnerability, :state))
          expect(vulnerability.severity).to eq(params.dig(:vulnerability, :severity))
          expect(vulnerability.confidence).to eq(params.dig(:vulnerability, :confidence))
        end

        it 'creates associated objects', :aggregate_failures do
          expect { subject }.to change(Vulnerabilities::Finding, :count).by(1)
            .and change(Vulnerabilities::Scanner, :count).by(1)
            .and change(Vulnerabilities::Identifier, :count).by(1)
        end

        context 'when Scanner already exists' do
          let!(:scanner) { create(:vulnerabilities_scanner, name: scanner_params[:name]) }

          it 'does not create a new Scanner' do
            expect { subject }.to change(Vulnerabilities::Scanner, :count).by(0)
          end
        end

        context 'when Identifier already exists' do
          let!(:identifier) { create(:vulnerabilities_identifier, name: identifier_params[:name]) }

          it 'does not create a new Identifier' do
            expect { subject }.not_to change(Vulnerabilities::Identifier, :count)
          end
        end

        it 'creates all objects with correct attributes' do
          expect(vulnerability.title).to eq(params.dig(:vulnerability, :title))
          expect(vulnerability.report_type).to eq("generic")
          expect(vulnerability.state).to eq(params.dig(:vulnerability, :state))
          expect(vulnerability.severity).to eq(params.dig(:vulnerability, :severity))
          expect(vulnerability.confidence).to eq(params.dig(:vulnerability, :confidence))

          finding = vulnerability.finding
          expect(finding.report_type).to eq("generic")
          expect(finding.severity).to eq(params.dig(:vulnerability, :severity))
          expect(finding.confidence).to eq(params.dig(:vulnerability, :confidence))

          scanner = finding.scanner
          expect(scanner.name).to eq(params.dig(:vulnerability, :scanner, :name))

          primary_identifier = finding.primary_identifier
          expect(primary_identifier.name).to eq(params.dig(:vulnerability, :identifiers, 0, :name))
        end

        context "when state fields match state" do
          let(:params) do
            {
              vulnerability: {
                title: "Test vulnerability",
                state: "confirmed",
                severity: "unknown",
                confidence: "unknown",
                confirmed_at: Time.now.iso8601,
                identifiers: [identifier_params],
                scanner: scanner_params
              }
            }
          end

          it 'creates Vulnerability in a different state with timestamps' do
            freeze_time do
              expect(vulnerability.state).to eq(params.dig(:vulnerability, :state))
              expect(vulnerability.confirmed_at).to eq(params.dig(:vulnerability, :confirmed_at))
              expect(vulnerability.confirmed_by).to eq(user)
            end
          end
        end

        context "when state fields don't match state" do
          let(:params) do
            {
              vulnerability: {
                title: "Test vulnerability",
                state: "detected",
                severity: "unknown",
                confidence: "unknown",
                confirmed_at: Time.now.iso8601,
                identifiers: [identifier_params],
                scanner: scanner_params
              }
            }
          end

          it 'returns an error' do
            result = subject
            expect(result.success?).to be_falsey
            expect(subject.message).to match(/confirmed_at can only be set/)
          end
        end
      end

      context 'with invalid parameters' do
        let(:params) do
          {
            vulnerability: {
              identifiers: [{
                name: "Test identfier 1",
                url: "https://test.com"
              }],
              scanner: {
                name: "My manual scanner"
              }
            }
          }
        end

        it 'returns an error' do
          expect(subject.error?).to be_truthy
        end
      end
    end
  end

  context 'when user does not have rights to dismiss a vulnerability' do
    let(:params) { {} }

    before do
      project.add_reporter(user)
    end

    it 'raises an "access denied" error' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
