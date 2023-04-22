# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinePresenter do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, project: project) }

  let(:presenter) { described_class.new(pipeline) }

  describe '#failure_reason' do
    context 'when pipeline has failure reason' do
      it 'represents a failure reason sentence' do
        pipeline.failure_reason = :job_activity_limit_exceeded

        expect(presenter.failure_reason)
          .to eq 'The pipeline job activity limit was exceeded.'
      end
    end

    context 'when pipeline does not have failure reason' do
      it 'returns nil' do
        expect(presenter.failure_reason).to be_nil
      end
    end
  end

  describe '#expose_security_dashboard?' do
    subject { presenter.expose_security_dashboard? }

    let(:current_user) { create(:user) }

    before do
      allow(presenter).to receive(:current_user) { current_user }
    end

    context 'with developer' do
      before do
        project.add_developer(current_user)
      end

      context 'when features are available' do
        before do
          stub_licensed_features(dependency_scanning: true, license_scanning: true, security_dashboard: true)
        end

        context 'when there is an artifact of a right type' do
          let!(:build) { create(:ee_ci_build, :dependency_scanning, pipeline: pipeline) }

          it { is_expected.to be_truthy }
        end

        context 'when there is an artifact of a wrong type' do
          let!(:build) { create(:ee_ci_build, :license_scanning, pipeline: pipeline) }

          it { is_expected.to be_falsey }
        end

        context 'when there is no found artifact' do
          let!(:build) { create(:ee_ci_build, pipeline: pipeline) }

          it { is_expected.to be_falsey }
        end

        it 'calls latest_report_artifacts once' do
          expect(pipeline).to receive(:latest_report_artifacts).once.and_call_original
          subject
        end
      end

      context 'when all features are available' do
        before do
          stub_licensed_features(
            dependency_scanning: true, secret_detection: true, sast: true, container_scanning: true,
            cluster_image_scanning: true, dast: true, coverage_fuzzing: true, api_fuzzing: true,
            license_scanning: true, security_dashboard: true
          )
        end

        it 'does not increase the number of queries' do
          all_features_query_count = count_ci_artifacts_queries

          stub_licensed_features(
            dependency_scanning: true, secret_detection: true, sast: true, container_scanning: true,
            cluster_image_scanning: false, dast: false, coverage_fuzzing: false, api_fuzzing: false,
            license_scanning: true, security_dashboard: true
          )

          less_features_query_count = count_ci_artifacts_queries

          expect(all_features_query_count).to eq(less_features_query_count)
        end

        it 'calls latest_report_artifacts once' do
          expect(pipeline).to receive(:latest_report_artifacts).once.and_call_original
          subject
        end
      end

      context 'when features are disabled' do
        context 'when there is an artifact of a right type' do
          let!(:build) { create(:ee_ci_build, :dependency_scanning, pipeline: pipeline) }

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'with reporter' do
      let!(:build) { create(:ee_ci_build, :dependency_scanning, pipeline: pipeline) }

      before do
        project.add_reporter(current_user)
        stub_licensed_features(dependency_scanning: true, license_scanning: true, security_dashboard: true)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#downloadable_path_for_report_type' do
    let(:current_user) { create(:user) }

    before do
      allow(presenter).to receive(:current_user) { current_user }
    end

    shared_examples '#downloadable_path_for_report_type' do |file_type, license|
      context 'when feature is available' do
        before do
          stub_licensed_features("#{license}": true)
          project.add_reporter(current_user)
        end

        it 'returns the downloadable path' do
          expect(presenter.downloadable_path_for_report_type(file_type)).to include(
            "#{project.full_path}/-/jobs/#{pipeline.builds.last.id}/artifacts/download?file_type=#{pipeline.builds.last.job_artifacts.last.file_type}")
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features("#{license}": false)
          project.add_reporter(current_user)
        end

        it 'doesn\'t return the downloadable path' do
          expect(presenter.downloadable_path_for_report_type(file_type)).to eq(nil)
        end
      end

      context 'when user is not authorized' do
        before do
          stub_licensed_features("#{license}": true)
          project.add_guest(current_user)
        end

        it 'doesn\'t return the downloadable path' do
          expect(presenter.downloadable_path_for_report_type(file_type)).to eq(nil)
        end
      end
    end

    context 'with browser_performance artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_browser_performance_report, project: project) }

      include_examples '#downloadable_path_for_report_type', :browser_performance, :merge_request_performance_metrics
    end

    context 'with load_performance artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_load_performance_report, project: project) }

      include_examples '#downloadable_path_for_report_type', :load_performance, :merge_request_performance_metrics
    end

    context 'with license_scanning artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      include_examples '#downloadable_path_for_report_type', :license_scanning, :license_scanning
    end
  end

  describe '#degradation_threshold' do
    let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_browser_performance_report, project: project) }

    let(:current_user) { create(:user) }

    before do
      allow(presenter).to receive(:current_user) { current_user }
      allow_any_instance_of(Ci::Build).to receive(:degradation_threshold).and_return(1)
    end

    context 'when feature is available' do
      before do
        project.add_reporter(current_user)
        stub_licensed_features(merge_request_performance_metrics: true)
      end

      it 'returns the degradation threshold' do
        expect(presenter.degradation_threshold(:browser_performance)).to eq(1)
      end
    end

    context 'when feature is not available' do
      before do
        project.add_reporter(current_user)
        stub_licensed_features(merge_request_performance_metrics: false)
      end

      it 'doesn\'t return the degradation threshold' do
        expect(presenter.degradation_threshold(:browser_performance)).to eq(nil)
      end
    end

    context 'when user is not authorized' do
      before do
        project.add_guest(current_user)
        stub_licensed_features(merge_request_performance_metrics: true)
      end

      it 'doesn\'t return the degradation threshold' do
        expect(presenter.degradation_threshold(:browser_performance)).to eq(nil)
      end
    end
  end

  describe '#retryable?' do
    subject { presenter.retryable? }

    let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    context 'with pipeline for merge train' do
      let(:pipeline) { merge_request.all_pipelines.last }
      let(:merge_request) { create(:merge_request, :on_train, :with_merge_train_pipeline) }

      it { is_expected.to be false }
    end

    context 'with branch pipeline' do
      it { is_expected.to be true }
    end
  end

  def count_ci_artifacts_queries
    query_recorder = ActiveRecord::QueryRecorder.new { presenter.expose_security_dashboard? }
    query_recorder.log.count { |q| q.include?('FROM "ci_job_artifacts"') }
  end
end
