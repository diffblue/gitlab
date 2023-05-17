# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::ProcessPrometheusAlertService, feature_category: :incident_management do
  let_it_be(:project, refind: true) { create(:project) }

  describe '#execute' do
    let(:service) { described_class.new(project, payload) }

    subject(:execute) { service.execute }

    context 'when alert payload is valid' do
      let_it_be(:starts_at) { '2020-04-27T10:10:22.265949279Z' }
      let_it_be(:title) { 'Alert title' }
      let_it_be(:plain_fingerprint) { [starts_at, title, 'vector(1)'].join('/') }
      let_it_be(:gitlab_fingerprint) { Digest::SHA1.hexdigest(plain_fingerprint) }

      let(:payload) { raw_payload }
      let(:raw_payload) do
        {
          'status' => 'firing',
          'labels' => { 'alertname' => 'GitalyFileServerDown' },
          'annotations' => { 'title' => title, 'alt_title' => "alt-#{title}" },
          'startsAt' => starts_at,
          'endsAt' => '2020-04-27T10:20:22.265949279Z',
          'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
        }
      end

      it_behaves_like 'does not create or delete any escalations'

      context 'with escalation policies feature enabled' do
        let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }

        before do
          stub_licensed_features(oncall_schedules: true, escalation_policies: true)
        end

        include_examples 'creates an escalation'

        context 'with an existing alert' do
          let!(:target) { create(:alert_management_alert, :from_payload, project: project, payload: payload, fingerprint: gitlab_fingerprint) }
          let!(:pending_escalation) { create(:incident_management_pending_alert_escalation, alert: target) }

          it_behaves_like 'does not create or delete any escalations'

          context 'with resolving payload' do
            let(:payload) { raw_payload.merge('status' => 'resolved') }

            include_examples "deletes the target's escalations"
          end
        end
      end

      context 'with HTTP integration provided' do
        let_it_be(:payload_example) { { 'annotations' => { 'alt_title' => 'alt-title' } } }
        let_it_be(:payload_attribute_mapping) do
          { 'title' => { 'path' => %w[annotations alt_title], 'type' => 'string' } }
        end

        let_it_be(:integration) do
          create(
            :alert_management_prometheus_integration,
            project: project,
            payload_attribute_mapping: payload_attribute_mapping,
            payload_example: payload_example
          )
        end

        let(:service) { described_class.new(project, payload, integration: integration) }

        it 'ignores the custom mapping' do
          execute

          expect(AlertManagement::Alert.last!.title).to eq(title)
        end

        context 'with custom mappings feature enabled' do
          before do
            stub_licensed_features(multiple_alert_http_integrations: true)
          end

          it 'respects the custom mapping' do
            execute

            expect(AlertManagement::Alert.last!.title).to eq("alt-#{title}")
          end
        end
      end
    end
  end
end
