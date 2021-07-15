# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipeline do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  describe 'associations' do
    it { is_expected.to have_many(:security_scans).through(:builds).class_name('Security::Scan') }
    it { is_expected.to have_many(:security_findings).through(:security_scans).class_name('Security::Finding').source(:findings) }
    it { is_expected.to have_many(:downstream_bridges) }
    it { is_expected.to have_many(:vulnerability_findings).through(:vulnerabilities_finding_pipelines).class_name('Vulnerabilities::Finding') }
    it { is_expected.to have_many(:vulnerabilities_finding_pipelines).class_name('Vulnerabilities::FindingPipeline') }
    it { is_expected.to have_one(:dast_profiles_pipeline).class_name('Dast::ProfilesPipeline').with_foreign_key(:ci_pipeline_id).inverse_of(:ci_pipeline) }
    it { is_expected.to have_one(:dast_profile).class_name('Dast::Profile').through(:dast_profiles_pipeline) }
    it { is_expected.to have_one(:dast_site_profiles_pipeline).class_name('Dast::SiteProfilesPipeline').with_foreign_key(:ci_pipeline_id).inverse_of(:ci_pipeline) }
    it { is_expected.to have_one(:dast_site_profile).class_name('DastSiteProfile').through(:dast_site_profiles_pipeline) }
  end

  describe '.failure_reasons' do
    it 'contains failure reasons about exceeded limits' do
      expect(described_class.failure_reasons)
        .to include 'activity_limit_exceeded', 'size_limit_exceeded'
    end
  end

  describe '#with_vulnerabilities scope' do
    let!(:pipeline_1) { create(:ci_pipeline, project: project) }
    let!(:pipeline_2) { create(:ci_pipeline, project: project) }
    let!(:pipeline_3) { create(:ci_pipeline, project: project) }

    before do
      create(:vulnerabilities_finding, pipelines: [pipeline_1], project: pipeline.project)
      create(:vulnerabilities_finding, pipelines: [pipeline_2], project: pipeline.project)
    end

    it "returns pipeline with vulnerabilities" do
      expect(described_class.with_vulnerabilities).to contain_exactly(pipeline_1, pipeline_2)
    end
  end

  describe '#batch_lookup_report_artifact_for_file_type' do
    shared_examples '#batch_lookup_report_artifact_for_file_type' do |file_type, license|
      context 'when feature is available' do
        before do
          stub_licensed_features("#{license}": true)
        end

        it "returns the #{file_type} artifact" do
          expect(pipeline.batch_lookup_report_artifact_for_file_type(file_type)).to eq(pipeline.job_artifacts.sample)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features("#{license}": false)
        end

        it "doesn't return the #{file_type} artifact" do
          expect(pipeline.batch_lookup_report_artifact_for_file_type(file_type)).to be_nil
        end
      end
    end

    context 'with security report artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

      include_examples '#batch_lookup_report_artifact_for_file_type', :dependency_scanning, :dependency_scanning
    end

    context 'with license scanning artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      include_examples '#batch_lookup_report_artifact_for_file_type', :license_scanning, :license_scanning
    end

    context 'with browser performance artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_browser_performance_report, project: project) }

      include_examples '#batch_lookup_report_artifact_for_file_type', :browser_performance, :merge_request_performance_metrics
    end

    context 'with load performance artifact' do
      let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, :with_load_performance_report, project: project) }

      include_examples '#batch_lookup_report_artifact_for_file_type', :load_performance, :merge_request_performance_metrics
    end
  end

  describe '#expose_license_scanning_data?' do
    subject { pipeline.expose_license_scanning_data? }

    before do
      stub_licensed_features(license_scanning: true)
      create(:ee_ci_build, :license_scanning, pipeline: pipeline)
    end

    it { is_expected.to be_truthy }
  end

  describe '#security_reports' do
    subject { pipeline.security_reports }

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, cluster_image_scanning: true)
    end

    context 'when pipeline has multiple builds with security reports' do
      let(:build_sast_1) { create(:ci_build, :success, name: 'sast_1', pipeline: pipeline, project: project) }
      let(:build_sast_2) { create(:ci_build, :success, name: 'sast_2', pipeline: pipeline, project: project) }
      let(:build_ds_1) { create(:ci_build, :success, name: 'ds_1', pipeline: pipeline, project: project) }
      let(:build_ds_2) { create(:ci_build, :success, name: 'ds_2', pipeline: pipeline, project: project) }
      let(:build_cs_1) { create(:ci_build, :success, name: 'cs_1', pipeline: pipeline, project: project) }
      let(:build_cs_2) { create(:ci_build, :success, name: 'cs_2', pipeline: pipeline, project: project) }
      let(:build_cis_1) { create(:ci_build, :success, name: 'cis_1', pipeline: pipeline, project: project) }
      let(:build_cis_2) { create(:ci_build, :success, name: 'cis_2', pipeline: pipeline, project: project) }
      let!(:sast1_artifact) { create(:ee_ci_job_artifact, :sast, job: build_sast_1, project: project) }
      let!(:sast2_artifact) { create(:ee_ci_job_artifact, :sast, job: build_sast_2, project: project) }
      let!(:ds1_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds_1, project: project) }
      let!(:ds2_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds_2, project: project) }
      let!(:cs1_artifact) { create(:ee_ci_job_artifact, :container_scanning, job: build_cs_1, project: project) }
      let!(:cs2_artifact) { create(:ee_ci_job_artifact, :container_scanning, job: build_cs_2, project: project) }
      let!(:cis1_artifact) { create(:ee_ci_job_artifact, :cluster_image_scanning, job: build_cis_1, project: project) }
      let!(:cis2_artifact) { create(:ee_ci_job_artifact, :cluster_image_scanning, job: build_cis_2, project: project) }

      it 'assigns pipeline to the reports' do
        expect(subject.pipeline).to eq(pipeline)
        expect(subject.reports.values.map(&:pipeline).uniq).to contain_exactly(pipeline)
      end

      it 'returns security reports with collected data grouped as expected' do
        expect(subject.reports.keys).to contain_exactly('sast', 'dependency_scanning', 'container_scanning', 'cluster_image_scanning')

        # for each of report categories, we have merged 2 reports with the same data (fixture)
        expect(subject.get_report('sast', sast1_artifact).findings.size).to eq(5)
        expect(subject.get_report('dependency_scanning', ds1_artifact).findings.size).to eq(4)
        expect(subject.get_report('container_scanning', cs1_artifact).findings.size).to eq(8)
        expect(subject.get_report('cluster_image_scanning', cis1_artifact).findings.size).to eq(2)
      end

      context 'when builds are retried' do
        let(:build_sast_1) { create(:ci_build, :retried, name: 'sast_1', pipeline: pipeline, project: project) }

        it 'does not take retried builds into account' do
          expect(subject.get_report('sast', sast1_artifact).findings.size).to eq(5)
          expect(subject.get_report('dependency_scanning', ds1_artifact).findings.size).to eq(4)
          expect(subject.get_report('container_scanning', cs1_artifact).findings.size).to eq(8)
          expect(subject.get_report('cluster_image_scanning', cis1_artifact).findings.size).to eq(2)
        end
      end

      context 'when the `report_types` parameter is provided' do
        subject(:filtered_report_types) { pipeline.security_reports(report_types: %w(sast)).reports.values.map(&:type).uniq }

        it 'returns only the reports which are requested' do
          expect(filtered_report_types).to eq(%w(sast))
        end
      end
    end

    context 'when pipeline does not have any builds with security reports' do
      it 'returns empty security reports' do
        expect(subject.reports).to eq({})
      end
    end
  end

  describe '::Security::StoreScansWorker' do
    shared_examples_for 'storing the security scans' do |transition|
      subject(:transition_pipeline) { pipeline.update!(status_event: transition) }

      before do
        allow(::Security::StoreScansWorker).to receive(:perform_async)
        allow(pipeline).to receive(:can_store_security_reports?).and_return(can_store_security_reports)
      end

      context 'when the security scans can be stored for the pipeline' do
        let(:can_store_security_reports) { true }

        it 'schedules store security scans job' do
          transition_pipeline

          expect(::Security::StoreScansWorker).to have_received(:perform_async).with(pipeline.id)
        end
      end

      context 'when the security scans can not be stored for the pipeline' do
        let(:can_store_security_reports) { false }

        it 'does not schedule store security scans job' do
          transition_pipeline

          expect(::Security::StoreScansWorker).not_to have_received(:perform_async)
        end
      end
    end

    context 'when pipeline is succeeded' do
      it_behaves_like 'storing the security scans', :succeed
    end

    context 'when pipeline is dropped' do
      it_behaves_like 'storing the security scans', :drop
    end

    context 'when pipeline is skipped' do
      it_behaves_like 'storing the security scans', :skip
    end

    context 'when pipeline is canceled' do
      it_behaves_like 'storing the security scans', :cancel
    end
  end

  describe '#license_scanning_reports' do
    subject { pipeline.license_scanning_report }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context 'when pipeline has multiple builds with license scanning reports' do
      let!(:build_1) { create(:ee_ci_build, :success, :license_scanning, pipeline: pipeline, project: project) }
      let!(:build_2) { create(:ee_ci_build, :success, :license_scanning_feature_branch, pipeline: pipeline, project: project) }

      it 'returns a license scanning report with collected data' do
        expect(subject.licenses.count).to eq(5)
        expect(subject.licenses.map(&:name)).to include('WTFPL', 'MIT')
      end

      context 'when builds are retried' do
        before do
          build_1.update!(retried: true)
          build_2.update!(retried: true)
        end

        it 'does not take retried builds into account' do
          expect(subject.licenses).to be_empty
        end
      end
    end

    context 'when pipeline does not have any builds with license scanning reports' do
      it 'returns an empty license scanning report' do
        expect(subject.licenses).to be_empty
      end
    end
  end

  describe '#dependency_list_reports' do
    subject { pipeline.dependency_list_report }

    before do
      stub_licensed_features(dependency_scanning: true)
    end

    context 'when pipeline has a build with dependency list reports' do
      let!(:build) { create(:ee_ci_build, :success, :dependency_list, pipeline: pipeline, project: project) }
      let!(:build1) { create(:ee_ci_build, :success, :dependency_scanning, pipeline: pipeline, project: project) }
      let!(:build2) { create(:ee_ci_build, :success, :license_scanning, pipeline: pipeline, project: project) }

      it 'returns a dependency list report with collected data' do
        mini_portile2 = subject.dependencies.find { |x| x[:name] == 'mini_portile2' }

        expect(subject.dependencies.count).to eq(21)
        expect(mini_portile2[:name]).not_to be_empty
        expect(mini_portile2[:licenses]).not_to be_empty
      end

      context 'when builds are retried' do
        before do
          build.update!(retried: true)
          build1.update!(retried: true)
        end

        it 'does not take retried builds into account' do
          expect(subject.dependencies).to be_empty
        end
      end
    end

    context 'when pipeline does not have any builds with dependency_list reports' do
      it 'returns an empty dependency_list report' do
        expect(subject.dependencies).to be_empty
      end
    end
  end

  describe '#metrics_report' do
    subject { pipeline.metrics_report }

    before do
      stub_licensed_features(metrics_reports: true)
    end

    context 'when pipeline has multiple builds with metrics reports' do
      before do
        create(:ee_ci_build, :success, :metrics, pipeline: pipeline, project: project)
      end

      it 'returns a metrics report with collected data' do
        expect(subject.metrics.count).to eq(2)
      end
    end

    context 'when pipeline has multiple builds with metrics reports that are retried' do
      before do
        create_list(:ee_ci_build, 2, :retried, :success, :metrics, pipeline: pipeline, project: project)
      end

      it 'does not take retried builds into account' do
        expect(subject.metrics).to be_empty
      end
    end

    context 'when pipeline does not have any builds with metrics reports' do
      it 'returns an empty metrics report' do
        expect(subject.metrics).to be_empty
      end
    end
  end

  describe 'state machine transitions' do
    context 'on pipeline complete' do
      let(:pipeline) { create(:ci_empty_pipeline, status: from_status) }

      Ci::HasStatus::ACTIVE_STATUSES.each do |status|
        context "from #{status}" do
          let(:from_status) { status }

          it 'schedules Ci::SyncReportsToReportApprovalRulesWorker' do
            expect(Ci::SyncReportsToReportApprovalRulesWorker).to receive(:perform_async).with(pipeline.id)

            pipeline.succeed
          end
        end
      end
    end

    context 'when pipeline has downstream bridges' do
      before do
        pipeline.downstream_bridges << create(:ci_bridge)
      end

      context "when transitioning to success" do
        it 'schedules the pipeline bridge worker' do
          expect(::Ci::PipelineBridgeStatusWorker).to receive(:perform_async).with(pipeline.id)

          pipeline.succeed!
        end
      end

      context 'when transitioning to blocked' do
        it 'schedules the pipeline bridge worker' do
          expect(::Ci::PipelineBridgeStatusWorker).to receive(:perform_async).with(pipeline.id)

          pipeline.block!
        end
      end
    end

    context 'when pipeline project has downstream subscriptions' do
      let(:pipeline) { create(:ci_empty_pipeline, project: create(:project, :public)) }

      before do
        pipeline.project.downstream_projects << create(:project)
      end

      context 'when pipeline runs on a tag' do
        before do
          pipeline.update!(tag: true)
        end

        context 'when feature is not available' do
          before do
            stub_licensed_features(ci_project_subscriptions: false)
          end

          it 'does not schedule the trigger downstream subscriptions worker' do
            expect(::Ci::TriggerDownstreamSubscriptionsWorker).not_to receive(:perform_async)

            pipeline.succeed!
          end
        end

        context 'when feature is available' do
          before do
            stub_licensed_features(ci_project_subscriptions: true)
          end

          it 'schedules the trigger downstream subscriptions worker' do
            expect(::Ci::TriggerDownstreamSubscriptionsWorker).to receive(:perform_async)

            pipeline.succeed!
          end
        end
      end
    end
  end

  describe '#latest_merged_result_pipeline?' do
    subject { pipeline.latest_merged_result_pipeline? }

    let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }
    let(:pipeline) { merge_request.all_pipelines.first }
    let(:args) { {} }

    it { is_expected.to be_truthy }

    context 'when pipeline is not merge request pipeline' do
      let(:pipeline) { build(:ci_pipeline) }

      it { is_expected.to be_falsy }
    end

    context 'when source sha is outdated' do
      before do
        pipeline.source_sha = merge_request.diff_base_sha
      end

      it { is_expected.to be_falsy }
    end

    context 'when target sha is outdated' do
      before do
        pipeline.target_sha = 'old-sha'
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#retryable?' do
    subject { pipeline.retryable? }

    let(:pipeline) { merge_request.all_pipelines.last }
    let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    context 'with pipeline for merged results' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to be true }
    end
  end

  describe '#merge_train_pipeline?' do
    subject { pipeline.merge_train_pipeline? }

    let!(:pipeline) do
      create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, ref: ref, target_sha: 'xxx')
    end

    let(:merge_request) { create(:merge_request) }
    let(:ref) { 'refs/merge-requests/1/train' }

    it { is_expected.to be_truthy }

    context 'when ref is merge ref' do
      let(:ref) { 'refs/merge-requests/1/merge' }

      it { is_expected.to be_falsy }
    end
  end

  describe '#merge_request_event_type' do
    subject { pipeline.merge_request_event_type }

    let(:pipeline) { merge_request.all_pipelines.last }

    context 'when pipeline is merge train pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_train_pipeline) }

      it { is_expected.to eq(:merge_train) }
    end

    context 'when pipeline is merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to eq(:merged_result) }
    end

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }

      it { is_expected.to eq(:detached) }
    end
  end

  describe '#latest_failed_security_builds' do
    let(:sast_build) { create(:ee_ci_build, :sast, :failed, pipeline: pipeline) }
    let(:dast_build) { create(:ee_ci_build, :sast, pipeline: pipeline) }
    let(:retried_sast_build) { create(:ee_ci_build, :sast, :failed, :retried, pipeline: pipeline) }
    let(:expected_builds) { [sast_build] }

    before do
      allow_next_instance_of(::Security::SecurityJobsFinder) do |finder|
        allow(finder).to receive(:execute).and_return([sast_build, dast_build, retried_sast_build])
      end
    end

    subject { pipeline.latest_failed_security_builds }

    it { is_expected.to match_array(expected_builds) }
  end

  describe "#license_scan_completed?" do
    where(:pipeline_status, :build_types, :expected_status) do
      [
        [:blocked, [:container_scanning], false],
        [:blocked, [:cluster_image_scanning], false],
        [:blocked, [:license_scan_v2_1, :container_scanning], true],
        [:blocked, [:license_scan_v2_1], true],
        [:blocked, [], false],
        [:failed, [:container_scanning], false],
        [:failed, [:cluster_image_scanning], false],
        [:failed, [:license_scan_v2_1, :container_scanning], true],
        [:failed, [:license_scan_v2_1], true],
        [:failed, [], false],
        [:running, [:container_scanning], false],
        [:running, [:cluster_image_scanning], false],
        [:running, [:license_scan_v2_1, :container_scanning], true],
        [:running, [:license_scan_v2_1], true],
        [:running, [], false],
        [:success, [:container_scanning], false],
        [:success, [:cluster_image_scanning], false],
        [:success, [:license_scan_v2_1, :container_scanning], true],
        [:success, [:license_scan_v2_1], true],
        [:success, [], false]
      ]
    end

    with_them do
      subject { pipeline.license_scan_completed? }

      let(:pipeline) { create(:ci_pipeline, pipeline_status, builds: builds) }
      let(:builds) { build_types.map { |build_type| create(:ee_ci_build, build_type) } }

      specify { expect(subject).to eq(expected_status) }
    end
  end

  describe '#can_store_security_reports?' do
    subject { pipeline.can_store_security_reports? }

    before do
      pipeline.succeed!
    end

    context 'when the security reports can not be stored for the project' do
      before do
        allow(project).to receive(:can_store_security_reports?).and_return(false)
      end

      context 'when the pipeline does not have security reports' do
        it { is_expected.to be_falsy }
      end

      context 'when the pipeline has security reports' do
        before do
          create(:ee_ci_build, :sast, pipeline: pipeline, project: project)
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when the security reports can be stored for the project' do
      before do
        allow(project).to receive(:can_store_security_reports?).and_return(true)
      end

      context 'when the pipeline does not have security reports' do
        it { is_expected.to be_falsy }
      end

      context 'when the pipeline has security reports' do
        before do
          create(:ee_ci_build, :sast, pipeline: pipeline, project: project)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#has_security_findings?' do
    subject { pipeline.has_security_findings? }

    context 'when the pipeline has security_findings' do
      before do
        scan = create(:security_scan, pipeline: pipeline)
        create(:security_finding, scan: scan)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the pipeline does not have security_findings' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#triggered_for_ondemand_dast_scan?' do
    let(:pipeline_params) { { source: :ondemand_dast_scan, config_source: :parameter_source } }
    let(:pipeline) { build(:ci_pipeline, pipeline_params) }

    subject { pipeline.triggered_for_ondemand_dast_scan? }

    context 'when the feature flag is enabled' do
      it { is_expected.to be_truthy }

      context 'when the pipeline only has the correct source' do
        let(:pipeline_params) { { source: :ondemand_dast_scan } }

        it { is_expected.to be_falsey }
      end

      context 'when the pipeline only has the correct config_source' do
        let(:pipeline_params) { { config_source: :parameter_source } }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#needs_touch?' do
    subject { pipeline.needs_touch? }

    context 'when pipeline was updated less than 5 minutes ago' do
      before do
        pipeline.updated_at = 4.minutes.ago
      end

      it { is_expected.to eq(false) }
    end

    context 'when pipeline was updated more than 5 minutes ago' do
      before do
        pipeline.updated_at = 6.minutes.ago
      end

      it { is_expected.to eq(true) }
    end
  end
end
