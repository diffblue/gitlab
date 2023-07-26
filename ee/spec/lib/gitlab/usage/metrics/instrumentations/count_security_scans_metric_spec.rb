# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountSecurityScansMetric, feature_category: :service_ping do
  RSpec.shared_examples 'a correct secure type instrumented metric value' do |params|
    let(:expected_value) { params[:expected_value] }

    before_all do
      ::Security::Scan.scan_types.except('cluster_image_scanning').each do |name, _|
        create(:security_scan, scan_type: name, created_at: 45.days.ago)
        create(:security_scan, scan_type: name, created_at: 3.days.ago)
      end
    end

    ::Security::Scan.scan_types.except('cluster_image_scanning').each do |name, scan_type|
      let(:scan_type) { scan_type }

      context "with scan_type #{name}" do
        let(:expected_query) do
          if params[:time_frame] == 'all'
            %{SELECT COUNT("security_scans"."build_id") FROM "security_scans" WHERE "security_scans"."scan_type" = #{scan_type}} # rubocop:disable Layout/LineLength
          else
            %{SELECT COUNT("security_scans"."build_id") FROM "security_scans" WHERE "security_scans"."created_at" BETWEEN '#{start}' AND '#{finish}' AND "security_scans"."scan_type" = #{scan_type}} # rubocop:disable Layout/LineLength
          end
        end

        it_behaves_like 'a correct instrumented metric value and query',
          { time_frame: params[:time_frame], data_source: 'database', options: { scan_type: name.to_s } }
      end
    end
  end

  context 'with time_frame all' do
    it_behaves_like 'a correct secure type instrumented metric value', { time_frame: 'all', expected_value: 2 }
  end

  context 'with time_frame 28d' do
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }

    it_behaves_like 'a correct secure type instrumented metric value', { time_frame: '28d', expected_value: 1 }
  end

  it 'raises an exception if scan_type option is not present' do
    expect do
      described_class.new(time_frame: 'all')
    end.to raise_error(ArgumentError, /scan_type must be present/)
  end

  it 'raises an exception if scan_type option is invalid' do
    expect do
      described_class.new(options: { scan_type: 'invalid_type' }, time_frame: 'all')
    end.to raise_error(ArgumentError, /scan_type must be present/)
  end
end
