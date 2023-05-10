# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestWidgetEntity do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create :project, :repository }
  let_it_be(:merge_request, reload: true) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:pipeline, reload: true) { create(:ci_empty_pipeline, project: project) }

  let(:request) { double('request', current_user: user) }

  before do
    stub_config_setting(relative_url_root: '/gitlab')
    project.add_developer(user)
  end

  subject(:entity) do
    described_class.new(merge_request, current_user: user, request: request)
  end

  def create_all_artifacts
    artifacts = %i(codequality performance browser_performance load_performance)

    artifacts.each do |artifact_type|
      create(:ee_ci_build, artifact_type, :success, pipeline: pipeline, project: pipeline.project)
    end

    pipeline.reload
  end

  it 'avoids N+1 queries', :request_store do
    allow(pipeline).to receive(:available_licensed_report_type?).and_return(true)
    allow(merge_request).to receive_messages(base_pipeline: pipeline, head_pipeline: pipeline)
    create_all_artifacts
    serializer = MergeRequestSerializer.new(current_user: user, project: project)

    serializer.represent(merge_request)

    RequestStore.clear!

    control = ActiveRecord::QueryRecorder.new { serializer.represent(merge_request) }

    create_all_artifacts
    RequestStore.clear!

    # Threshold of 1 query is added because of actor check on the feature flag mr_show_reports_immediately
    # TODO: remove the threshold when mr_show_reports_immediately feature flag is removed
    expect { serializer.represent(merge_request) }.not_to exceed_query_limit(control).with_threshold(1)
  end

  describe 'test report artifacts', :request_store do
    using RSpec::Parameterized::TableSyntax

    where(:json_entry, :artifact_type, :exposures) do
      :browser_performance | :browser_performance | [:degradation_threshold, :head_path, :base_path]
      :browser_performance | :performance         | [:degradation_threshold, :head_path, :base_path]
      :load_performance    | :load_performance    | [:head_path, :base_path]
    end

    with_them do
      before do
        allow(merge_request).to receive_messages(
          base_pipeline: pipeline,
          head_pipeline: pipeline
        )
      end

      context 'when feature is available' do
        before do
          allow(pipeline).to receive(:available_licensed_report_type?).and_return(true)
        end

        context "with new report artifacts" do
          before do
            create(:ee_ci_build, artifact_type, pipeline: pipeline)
          end

          it "has data entry" do
            expect(subject.as_json).to include(json_entry)
            exposures.each do |exposure|
              expect(subject.as_json[json_entry]).to include(exposure)
            end
          end
        end

        context "without artifacts" do
          it "does not have data entry" do
            expect(subject.as_json).not_to include(json_entry)
          end
        end
      end
    end
  end

  describe 'degradation_threshold' do
    let!(:head_pipeline) { create(:ci_empty_pipeline, project: project) }

    before do
      allow(merge_request).to receive_messages(
        base_pipeline: pipeline,
        head_pipeline: head_pipeline
      )

      allow(head_pipeline).to receive(:available_licensed_report_type?).and_return(true)
    end

    shared_examples 'degradation_threshold' do
      context "when head pipeline's browser performance build has the threshold variable defined" do
        let(:yaml_variables) do
          [
            { key: 'FOO', value: 'BAR' },
            { key: 'DEGRADATION_THRESHOLD', value: '5' }
          ]
        end

        it "returns the value of the variable" do
          expect(subject.as_json[:browser_performance][:degradation_threshold]).to eq(5)
        end
      end

      context "when head pipeline's browser performance build has no threshold variable defined" do
        let(:yaml_variables) do
          [
            { key: 'FOO', value: 'BAR' }
          ]
        end

        it "returns nil" do
          expect(subject.as_json[:browser_performance][:degradation_threshold]).to be_nil
        end
      end
    end

    context 'with browser_performance artifact' do
      before do
        create(
          :ee_ci_build,
          :browser_performance,
          pipeline: head_pipeline,
          yaml_variables: yaml_variables
        )
      end

      include_examples 'degradation_threshold'
    end

    context 'with performance artifact' do
      before do
        create(
          :ee_ci_build,
          :performance,
          pipeline: head_pipeline,
          yaml_variables: yaml_variables
        )
      end

      include_examples 'degradation_threshold'
    end
  end

  describe '#license_scanning', :request_store do
    before do
      stub_licensed_features(license_scanning: true)
    end

    context 'when report artifact is defined' do
      before do
        create(:ee_ci_build, :license_scanning, pipeline: pipeline)
      end

      it 'is included' do
        allow(merge_request).to receive_messages(head_pipeline: pipeline, target_project: project)

        expect(subject.as_json[:license_scanning]).to include(:can_manage_licenses)
        expect(subject.as_json[:license_scanning]).to include(:full_report_path)
      end

      it '#settings_path should not be included for developers' do
        expect(subject.as_json[:license_scanning]).not_to include(:settings_path)
      end

      context 'when feature is not licensed' do
        before do
          stub_licensed_features(license_scanning: false)
        end

        it 'is not included' do
          expect(subject.as_json).not_to include(:license_scanning)
        end
      end

      context 'when user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        it '#settings_path should be included for maintainers' do
          expect(subject.as_json[:license_scanning]).to include(:settings_path)
        end
      end

      context "when a report artifact is produced from a forked project" do
        let(:source_project) { fork_project(project, user, repository: true) }
        let(:fork_merge_request) { create(:merge_request, source_project: source_project, target_project: project) }
        let(:subject_json) { described_class.new(fork_merge_request, current_user: user, request: request).as_json }

        specify { expect(subject_json).to include(:license_scanning) }
      end
    end
  end

  it 'has vulnerability feedback paths' do
    expect(subject.as_json[:vulnerability_feedback_path]).to eq(
      "/#{merge_request.project.full_path}/-/vulnerability_feedback"
    )
    expect(subject.as_json).to include(:create_vulnerability_feedback_issue_path)
    expect(subject.as_json).to include(:create_vulnerability_feedback_merge_request_path)
    expect(subject.as_json).to include(:create_vulnerability_feedback_dismissal_path)
  end

  describe '#can_read_vulnerabilities' do
    context 'when security dashboard feature is available' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'is set to true' do
        expect(subject.as_json[:can_read_vulnerabilities]).to eq(true)
      end
    end

    context 'when security dashboard feature is not available' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'is set to false' do
        expect(subject.as_json[:can_read_vulnerabilities]).to eq(false)
      end
    end
  end

  describe '#can_read_vulnerability_feedback' do
    context 'when user has permissions to read vulnerability feedback' do
      before do
        project.add_developer(user)
      end

      it 'is set to true' do
        expect(subject.as_json[:can_read_vulnerability_feedback]).to eq(true)
      end
    end

    context 'when user has no permissions to read vulnerability feedback' do
      before do
        project.add_guest(user)
      end

      it 'is set to false' do
        expect(subject.as_json[:can_read_vulnerability_feedback]).to eq(false)
      end
    end
  end

  it 'has can_read_vulnerability_feedback property' do
    expect(subject.as_json).to include(:can_read_vulnerability_feedback)
  end

  it 'has discover project security path' do
    expect(subject.as_json).to include(:discover_project_security_path)
  end

  it 'has pipeline id' do
    allow(merge_request).to receive(:head_pipeline).and_return(pipeline)

    expect(subject.as_json).to include(:pipeline_id)
  end

  describe 'blocking merge requests' do
    let_it_be(:merge_request_block) { create(:merge_request_block, blocked_merge_request: merge_request) }

    let(:blocking_mr) { merge_request_block.blocking_merge_request }

    subject { entity.as_json[:blocking_merge_requests] }

    context 'feature disabled' do
      before do
        stub_licensed_features(blocking_merge_requests: false)
      end

      it 'does not have the blocking_merge_requests member' do
        expect(entity.as_json).not_to include(:blocking_merge_requests)
      end
    end

    context 'feature enabled' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      it 'shows the blocking merge request if visible' do
        blocking_mr.project.add_developer(user)

        is_expected.to include(
          hidden_count: 0,
          total_count: 1,
          visible_merge_requests: { opened: [kind_of(BlockingMergeRequestEntity)] }
        )
      end

      it 'hides the blocking merge request if not visible' do
        is_expected.to eq(
          hidden_count: 1,
          total_count: 1,
          visible_merge_requests: {}
        )
      end

      it 'does not count a merged and hidden blocking MR' do
        blocking_mr.update_columns(state_id: MergeRequest.available_states[:merged])

        is_expected.to eq(
          hidden_count: 0,
          total_count: 0,
          visible_merge_requests: {}
        )
      end
    end
  end
end
