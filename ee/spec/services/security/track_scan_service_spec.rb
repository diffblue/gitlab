# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TrackScanService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let_it_be_with_reload(:build) { create(:ee_ci_build, pipeline: pipeline, user: user) }

  describe '#execute' do
    subject { described_class.new(build).execute }

    context 'report has all metadata' do
      let_it_be(:dast_artifact) { create(:ee_ci_job_artifact, :dast_14_0_2, job: build) }

      before do
        allow(Digest::SHA256).to receive(:hexdigest).and_return('82fc6391e4be61e03e51fa8c5c6bfc32b3d3f0065ad2fe0a01211606952b8d82')
      end

      it 'tracks the scan event', :snowplow do
        subject

        expect_snowplow_event(
          category: 'secure::scan',
          action: 'scan',
          context: [{
                      schema: described_class::SECURE_SCAN_SCHEMA_URL,
                      data: {
                        analyzer: 'gitlab-dast',
                        analyzer_vendor: 'GitLab',
                        analyzer_version: '2.0.1',
                        end_time: '2021-06-11T07:27:50',
                        scan_type: 'dast',
                        scanner: 'zaproxy-browserker',
                        scanner_vendor: 'GitLab',
                        scanner_version: 'D-2020-08-26',
                        start_time: '2021-06-11T07:26:17',
                        status: 'success',
                        report_schema_version: '14.0.2'
                      }
                    }],
          idempotency_key: '82fc6391e4be61e03e51fa8c5c6bfc32b3d3f0065ad2fe0a01211606952b8d82',
          user: user.id,
          project: project.id,
          label: 'gitlab-dast',
          property: 'dast')
      end
    end

    context 'report is missing metadata' do
      let_it_be(:dast_artifact) { create(:ee_ci_job_artifact, :dast_missing_scan_field, job: build) }

      before do
        allow(Digest::SHA256).to receive(:hexdigest).and_return('62bc6c62686b327dbf420f8891e1418406b60f49e574b6ff22f4d6a272dbc595')
      end

      it 'tracks the scan event', :snowplow do
        subject

        expect_snowplow_event(
          category: 'secure::scan',
          action: 'scan',
          context: [{
                      schema: described_class::SECURE_SCAN_SCHEMA_URL,
                      data: {
                        analyzer: nil,
                        analyzer_vendor: nil,
                        analyzer_version: nil,
                        end_time: nil,
                        scan_type: 'dast',
                        scanner: "zaproxy",
                        scanner_vendor: nil,
                        scanner_version: nil,
                        start_time: nil,
                        status: 'success',
                        report_schema_version: '2.5'
                      }
                    }],
          idempotency_key: '62bc6c62686b327dbf420f8891e1418406b60f49e574b6ff22f4d6a272dbc595',
          user: user.id,
          project: project.id,
          label: nil,
          property: 'dast')
      end
    end
  end
end
