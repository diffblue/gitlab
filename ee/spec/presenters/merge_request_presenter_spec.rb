# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPresenter do
  using RSpec::Parameterized::TableSyntax

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:approval_feature_available) { true }

  before do
    stub_config_setting(relative_url_root: '/gitlab')
    stub_licensed_features(merge_request_approvers: approval_feature_available)
  end

  shared_examples 'is nil when needed' do
    where(:approval_feature_available, :with_iid) do
      false | false
      false | true
      true  | false
    end

    with_them do
      before do
        merge_request.iid = nil unless with_iid
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#api_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_approval_settings_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approval_settings")) }
  end

  describe '#api_project_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_project_approval_settings_path }

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/approval_settings")) }

    context "when approvals not available" do
      let(:approval_feature_available) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '#suggested_approvers' do
    subject { described_class.new(merge_request, current_user: user).suggested_approvers }

    it 'delegates to the approval state' do
      expect(merge_request.approval_state).to receive(:suggested_approvers).with(current_user: user) { [:ok] }

      is_expected.to contain_exactly(:ok)
    end
  end

  describe 'create vulnerability feedback paths' do
    where(:create_feedback_path) do
      [
        :create_vulnerability_feedback_issue_path,
        :create_vulnerability_feedback_merge_request_path,
        :create_vulnerability_feedback_dismissal_path
      ]
    end

    with_them do
      subject { described_class.new(merge_request, current_user: user).public_send(create_feedback_path, merge_request.project) }

      it { is_expected.to eq("/#{merge_request.project.full_path}/-/vulnerability_feedback") }

      context 'when not allowed to create vulnerability feedback' do
        let(:unauthorized_user) { create(:user) }

        subject { described_class.new(merge_request, current_user: unauthorized_user).public_send(create_feedback_path, merge_request.project) }

        it "does not contain #{params['create_feedback_path']}" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '#approvals_widget_type' do
    subject { described_class.new(merge_request, current_user: user).approvals_widget_type }

    context 'when approvals feature is available for a project' do
      let(:approval_feature_available) { true }

      it 'returns full' do
        is_expected.to eq('full')
      end
    end

    context 'when approvals feature is not available for a project' do
      let(:approval_feature_available) { false }

      it 'returns base' do
        is_expected.to eq('base')
      end
    end
  end

  describe '#missing_security_scan_types' do
    let(:presenter) { described_class.new(merge_request, current_user: user) }
    let(:pipeline) { instance_double(Ci::Pipeline) }

    subject(:missing_security_scan_types) { presenter.missing_security_scan_types }

    where(:feature_flag_enabled?, :can_read_pipeline?, :attribute_value) do
      false | false | nil
      false | true  | nil
      true  | false | nil
      true  | true  | %w(sast)
    end

    with_them do
      before do
        stub_feature_flags(missing_mr_security_scan_types: feature_flag_enabled?)
        allow(merge_request).to receive(:actual_head_pipeline).and_return(pipeline)
        allow(presenter).to receive(:can?).with(user, :read_pipeline, pipeline).and_return(can_read_pipeline?)
        allow(merge_request).to receive(:missing_security_scan_types).and_return(%w(sast))
      end

      it { is_expected.to eq(attribute_value) }
    end
  end

  describe '#discover_project_security_path' do
    let(:presenter) { described_class.new(merge_request, current_user: user) }
    let(:can_discover_project_security) { true }

    subject { presenter.discover_project_security_path }

    before do
      allow(presenter).to receive(:show_discover_project_security?) { can_discover_project_security }
    end

    context 'when project security is discoverable' do
      it 'returns path' do
        is_expected.to eq(presenter.project_security_discover_path(project))
      end
    end

    context 'when project security is not discoverable' do
      let(:can_discover_project_security) { false }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#issue_keys' do
    let(:presenter) { described_class.new(merge_request, current_user: user) }

    subject { presenter.issue_keys }

    context 'when Jira issue is provided in MR title / description' do
      let(:issue_key) { 'SIGNUP-1234' }

      before do
        merge_request.update!(title: "Fixes sign up issue #{issue_key}", description: "Related to #{issue_key}")
      end

      it { is_expected.to contain_exactly(issue_key) }
    end

    context 'when Jira issue is NOT provided in MR title / description' do
      before do
        merge_request.update!(title: "Fixes sign up issue", description: "Prevent spam sign ups by adding a rate limiter")
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#api_status_checks_path' do
    subject { presenter.api_status_checks_path }

    let(:exposed_path) { expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/status_checks") }

    where(:authenticated?, :has_status_checks?, :exposes_path?) do
      false | false | false
      false | true  | false
      true  | true  | true
      true  | false | false
      true  | true  | true
    end

    with_them do
      let(:presenter) { described_class.new(merge_request, current_user: authenticated? ? user : nil) }
      let(:path) { exposes_path? ? exposed_path : nil }

      before do
        allow(project.external_status_checks).to receive(:applicable_to_branch).and_return([{ branch: 'foo' }])
        allow(project.external_status_checks.applicable_to_branch).to receive(:any?).and_return(has_status_checks?)
      end

      it { is_expected.to eq(path) }
    end

    context 'with the user authenticated' do
      let(:presenter) { described_class.new(merge_request, current_user: user) }

      context 'without applicable branches' do
        before do
          create(:external_status_check, project: project, protected_branches: [create(:protected_branch, name: 'testbranch', project: project)])
        end

        it { is_expected.to eq(nil) }
      end

      context 'with no branches at all (any branch selected)' do
        before do
          create(:external_status_check, project: project, protected_branches: [])
        end

        it { is_expected.to eq(exposed_path) }
      end

      context 'with applicable branches' do
        before do
          create(:external_status_check, project: project, protected_branches: [create(:protected_branch, name: merge_request.target_branch, project: project)])
        end

        it { is_expected.to eq(exposed_path) }
      end
    end
  end
end
