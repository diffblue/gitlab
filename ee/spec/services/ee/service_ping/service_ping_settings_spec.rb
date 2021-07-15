# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ServicePing::ServicePingSettings do
  using RSpec::Parameterized::TableSyntax

  describe '#product_intelligence_enabled?' do
    where(:usage_ping_enabled, :customer_service_enabled, :requires_usage_stats_consent, :expected_product_intelligence_enabled) do
      # Customer service enabled
      true  | true  | false | true
      false | true  | true  | false
      false | true  | false | true
      true  | true  | true  | false

      # Customer service disabled
      true  | false | false | true
      true  | false | true  | false
      false | false | false | false
      false | false | true  | false

      # When there is no license it should have same behaviour as ce
      true  | nil | false | true
      false | nil | false | false
      false | nil | true  | false
      true  | nil | true  | false
    end

    with_them do
      before do
        allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: requires_usage_stats_consent))
        stub_config_setting(usage_ping_enabled: usage_ping_enabled)
        create_current_license(operational_metrics_enabled: customer_service_enabled)
      end

      it 'has the correct product_intelligence_enabled?' do
        expect(described_class.product_intelligence_enabled?).to eq(expected_product_intelligence_enabled)
      end
    end
  end
end
