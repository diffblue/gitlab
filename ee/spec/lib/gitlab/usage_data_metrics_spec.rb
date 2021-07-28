# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataMetrics do
  describe '.uncached_data' do
    subject { described_class.uncached_data }

    around do |example|
      described_class.instance_variable_set(:@definitions, nil)
      example.run
      described_class.instance_variable_set(:@definitions, nil)
    end

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false) # rubocop:disable Database/MultipleDatabases
    end

    context 'with instrumentation_class' do
      it 'includes top level keys' do
        expect(subject).to include(:license_md5)
        expect(subject).to include(:license_subscription_id)
      end

      it 'includes compliance monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:compliance].keys).to contain_exactly(*[
          :g_compliance_dashboard_monthly, :g_compliance_dashboard_weekly,
          :g_compliance_audit_events_monthly, :g_compliance_audit_events_weekly,
          :i_compliance_audit_events_monthly, :i_compliance_audit_events_weekly,
          :i_compliance_credential_inventory_monthly, :i_compliance_credential_inventory_weekly,
          :a_compliance_audit_events_api_monthly, :a_compliance_audit_events_api_weekly,
          :compliance_total_unique_counts_monthly, :compliance_total_unique_counts_weekly
        ])
      end
    end
  end
end
