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

      it 'includes incident_management_incident_published monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:incident_management]).to include(
          :incident_management_incident_published_monthly, :incident_management_incident_published_weekly
        )
      end

      it 'includes incident_management_oncall monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:incident_management_oncall].keys).to contain_exactly(*[
          :i_incident_management_oncall_notification_sent_monthly, :i_incident_management_oncall_notification_sent_weekly
        ])
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

      it 'includes search monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:search].keys).to contain_exactly(*[
          :i_search_total_monthly, :i_search_total_weekly,
          :i_search_advanced_monthly, :i_search_advanced_weekly,
          :i_search_paid_monthly, :i_search_paid_weekly,
          :search_total_unique_counts_monthly, :search_total_unique_counts_weekly
        ])
      end

      it 'includes testing monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:testing]).to include(
          :i_testing_metrics_report_widget_total_monthly, :i_testing_metrics_report_widget_total_weekly,
          :i_testing_group_code_coverage_visit_total_monthly, :i_testing_group_code_coverage_visit_total_weekly,
          :i_testing_full_code_quality_report_total_monthly, :i_testing_full_code_quality_report_total_weekly,
          :i_testing_web_performance_widget_total_monthly, :i_testing_web_performance_widget_total_weekly,
          :i_testing_group_code_coverage_project_click_total_monthly, :i_testing_group_code_coverage_project_click_total_weekly,
          :i_testing_load_performance_widget_total_monthly, :i_testing_load_performance_widget_total_weekly,
          :i_testing_metrics_report_artifact_uploaders_monthly, :i_testing_metrics_report_artifact_uploaders_weekly,
          :testing_total_unique_counts_weekly
        )
      end
    end
  end
end
