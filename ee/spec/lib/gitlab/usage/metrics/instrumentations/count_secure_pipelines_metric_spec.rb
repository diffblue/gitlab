# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountSecurePipelinesMetric, feature_category: :service_ping do
  let(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE }

  let_it_be(:user) { create(:user, group_view: :security_dashboard, created_at: 3.days.ago) }

  before do
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
  end

  before_all do
    travel_to(3.days.ago) do
      ::Security::Scan.scan_types.except('cluster_image_scanning').each do |name, _|
        create(:ci_build, name: name.to_s, user: user)
      end
    end
  end

  it 'raises an error for invalid scan types' do
    metric_definition = { time_frame: '28d', options: { scan_type: 'foo' } }

    expect { described_class.new(metric_definition) }.to raise_error(ArgumentError)
  end

  describe 'counts unique users correctly across multiple scanners' do
    let_it_be(:user2) { create(:user, group_view: :security_dashboard, created_at: 3.days.ago) }
    let_it_be(:user3) { create(:user, group_view: :security_dashboard, created_at: 3.days.ago) }

    before_all do
      create(:ci_build, name: 'sast', user: user2)
      create(:ci_build, name: 'dast', user: user2)
      create(:ci_build, name: 'dast', user: user3)
    end

    ::Security::Scan.scan_types.except('cluster_image_scanning').each do |name, _|
      it "has correct value for #{name}" do
        value = metric(name).value

        expect(value).to be_within(error_rate).percent_of(0)
      end
    end
  end

  describe 'counts pipelines that have security jobs' do
    before_all do
      travel_to(3.days.ago) do
        ds_build = create(:ci_build, name: 'gemnasium', user: user, status: 'success')
        ds_failed_build = create(:ci_build, :failed, user: user, name: 'gemnasium')
        ds_java_build = create(:ci_build, name: 'gemnasium-maven', user: user, commit_id: ds_build.pipeline.id,
          status: 'success')
        secret_detection_build = create(:ci_build, name: 'secret', user: user, commit_id: ds_build.pipeline.id,
          status: 'success')
        cs_build = create(:ci_build, name: 'container-scanning', user: user, status: 'success')
        sast_build = create(:ci_build, name: 'sast', user: user, status: 'success', retried: true)
        create(:security_scan, build: ds_build, scan_type: 'dependency_scanning')
        create(:security_scan, build: ds_java_build, scan_type: 'dependency_scanning')
        create(:security_scan, build: secret_detection_build, scan_type: 'secret_detection')
        create(:security_scan, build: cs_build, scan_type: 'container_scanning')
        create(:security_scan, build: sast_build, scan_type: 'sast')
        create(:security_scan, build: ds_failed_build, scan_type: 'dependency_scanning')
      end
    end

    it "for dependency_scanning" do
      value = metric('dependency_scanning').value

      expect(value).to be_within(error_rate).percent_of(2)
    end

    it "for sast" do
      value = metric('sast').value

      expect(value).to be_within(error_rate).percent_of(1)
    end

    it "for container_scanning" do
      value = metric('container_scanning').value

      expect(value).to be_within(error_rate).percent_of(1)
    end

    it "for secret_detection" do
      value = metric('secret_detection').value

      expect(value).to be_within(error_rate).percent_of(1)
    end

    it "for dast" do
      value = metric('dast').value

      expect(value).to be_within(error_rate).percent_of(0)
    end

    it "for coverage_fuzzing" do
      value = metric('coverage_fuzzing').value

      expect(value).to be_within(error_rate).percent_of(0)
    end

    it "for api_fuzzing" do
      value = metric('api_fuzzing').value

      expect(value).to be_within(error_rate).percent_of(0)
    end
  end

  ::Security::Scan.scan_types.except('cluster_image_scanning').each do |name, scan_type|
    context "with scan_type #{name}" do
      let(:start) { 30.days.ago.to_fs(:db) }
      let(:finish) { 2.days.ago.to_fs(:db) }
      let(:expected_query) do
        %{SELECT COUNT(DISTINCT "security_scans"."pipeline_id") FROM "security_scans" WHERE "security_scans"."created_at" BETWEEN '#{start}' AND '#{finish}' AND "security_scans"."scan_type" = #{scan_type}} # rubocop:disable Layout/LineLength
      end

      it 'has correct value' do
        metric = described_class.new(time_frame: '28d', data_source: 'database', options: { scan_type: name.to_s })

        expect(metric.value).to be_within(error_rate).percent_of(0)
      end

      it_behaves_like 'a correct instrumented metric query',
        { time_frame: '28d', data_source: 'database', options: { scan_type: name.to_s } }
    end
  end

  def metric(scan_type)
    described_class.new(time_frame: '28d', data_source: 'database', options: { scan_type: scan_type.to_s })
  end
end
