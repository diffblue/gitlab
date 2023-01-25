# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::BuildPayload, feature_category: :service_ping do
  describe '#execute' do
    subject(:service_ping_payload) { described_class.new.execute }

    include_context 'stubbed service ping metrics definitions' do
      let(:subscription_metrics) do
        [
          metric_attributes('license_md5', "subscription")
        ]
      end
    end

    before do
      allow(User).to receive(:single_user)
        .and_return(instance_double(User, :user, requires_usage_stats_consent?: false))
    end

    context 'GitLab instance have a license' do
      # License.current.present? == true
      context 'Instance consented to submit optional product intelligence data' do
        before do
          # Gitlab::CurrentSettings.usage_ping_enabled? == true
          stub_config_setting(usage_ping_enabled: true)
        end

        context 'Instance subscribes to free TAM service' do
          before do
            # License.current.usage_ping? == true
            create_current_license(operational_metrics_enabled: true)
          end

          it_behaves_like 'complete service ping payload'
        end

        context 'Instance does NOT subscribe to free TAM service' do
          before do
            # License.current.usage_ping? == false
            create_current_license(operational_metrics_enabled: false)
          end

          it_behaves_like 'service ping payload with all expected metrics' do
            let(:expected_metrics) { standard_metrics + subscription_metrics + optional_metrics + operational_metrics }
          end
        end
      end

      context 'Instance does NOT consented to submit optional product intelligence data' do
        before do
          # Gitlab::CurrentSettings.usage_ping_enabled? == false
          stub_config_setting(usage_ping_enabled: false)
        end

        context 'Instance subscribes to free TAM service' do
          before do
            # License.current.usage_ping? == true
            create_current_license(operational_metrics_enabled: true)
          end

          it_behaves_like 'service ping payload with all expected metrics' do
            let(:expected_metrics) { standard_metrics + subscription_metrics + operational_metrics }
          end

          it_behaves_like 'service ping payload without restricted metrics' do
            let(:restricted_metrics) { optional_metrics }
          end
        end

        context 'Instance does NOT subscribe to free TAM service' do
          before do
            # License.current.usage_ping? == false
            create_current_license(operational_metrics_enabled: false)
          end

          it_behaves_like 'complete service ping payload'
        end
      end
    end
  end
end
