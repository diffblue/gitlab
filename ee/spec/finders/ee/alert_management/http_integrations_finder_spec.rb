# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrationsFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:params) { {} }
    let_it_be(:active_integration) { create(:alert_management_http_integration, project: project, endpoint_identifier: 'abc123' ) }
    let_it_be(:inactive_integration) { create(:alert_management_http_integration, :inactive, project: project, endpoint_identifier: 'abc123' ) }
    let_it_be(:alt_identifier_integration) { create(:alert_management_http_integration, project: project) }
    let_it_be(:alt_project_integration) { create(:alert_management_http_integration) }

    before do
      stub_licensed_features(multiple_alert_http_integrations: true)
    end

    subject(:execute) { described_class.new(project, params).execute }

    context 'empty params' do
      it { is_expected.to contain_exactly(active_integration, inactive_integration, alt_identifier_integration) }
    end

    context 'endpoint_identifier given' do
      let(:params) { { endpoint_identifier: active_integration.endpoint_identifier } }

      it { is_expected.to contain_exactly(active_integration, inactive_integration) }

      context 'but unknown' do
        let(:params) { { endpoint_identifier: 'unknown' } }

        it { is_expected.to be_empty }
      end

      context 'but blank' do
        let(:params) { { endpoint_identifier: nil } }

        it { is_expected.to contain_exactly(active_integration, inactive_integration, alt_identifier_integration) }
      end
    end

    context 'active param given' do
      let(:params) { { active: true } }

      it { is_expected.to contain_exactly(active_integration, alt_identifier_integration) }

      context 'but blank' do
        let(:params) { { active: nil } }

        it { is_expected.to contain_exactly(active_integration, inactive_integration, alt_identifier_integration) }
      end
    end
  end
end
