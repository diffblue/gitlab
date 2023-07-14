# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrationsFinder, feature_category: :incident_management do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:active_integration) { create(:alert_management_http_integration, project: project, endpoint_identifier: 'abc123' ) }
    let_it_be(:inactive_integration) { create(:alert_management_http_integration, :inactive, project: project) }
    let_it_be(:prometheus_integration) { create(:alert_management_prometheus_integration, :inactive, project: project ) }
    let_it_be(:extra_prometheus_integration) { create(:alert_management_prometheus_integration, project: project ) }
    let_it_be(:alt_identifier_integration) { create(:alert_management_http_integration, project: project) }
    let_it_be(:alt_project_integration) { create(:alert_management_http_integration, endpoint_identifier: 'abc123') }

    let(:params) { {} }

    before do
      stub_licensed_features(multiple_alert_http_integrations: true)
    end

    subject(:execute) { described_class.new(project, params).execute }

    context 'empty params' do
      it do
        is_expected.to contain_exactly(
          active_integration,
          inactive_integration,
          alt_identifier_integration,
          prometheus_integration,
          extra_prometheus_integration
        )
      end
    end

    context 'endpoint_identifier given' do
      let(:params) { { endpoint_identifier: active_integration.endpoint_identifier } }

      it { is_expected.to contain_exactly(active_integration) }
    end

    context 'active param given' do
      let(:params) { { active: true } }

      it { is_expected.to contain_exactly(active_integration, alt_identifier_integration, extra_prometheus_integration) }
    end

    context 'type_identifier param given' do
      let(:params) { { type_identifier: :prometheus } }

      it { is_expected.to contain_exactly(prometheus_integration, extra_prometheus_integration) }
    end
  end
end
