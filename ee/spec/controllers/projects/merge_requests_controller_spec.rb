# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'authorize read pipeline' do
  context 'public project with private builds' do
    let_it_be(:project) { create(:project, :public, :builds_private) }

    let(:comparison_status) { {} }

    it 'restricts access to signed out users' do
      sign_out viewer

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'restricts access to other users' do
      sign_in create(:user)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'a security resource' do
  context 'public project with public builds' do
    let_it_be(:project) { create(:project, :public, :builds_enabled) }
    let_it_be(:non_member) { create(:user) }
    let_it_be(:guest) { create(:user).tap { |user| project.add_guest(user) } }

    let(:comparison_status) { {} }

    it 'restricts access from signed out users' do
      sign_out viewer

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'restricts access from non-members' do
      sign_in non_member

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'restricts access from guests' do
      sign_in guest

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'pending pipeline response' do
  context 'when pipeline is pending' do
    let(:comparison_status) { nil }

    before do
      merge_request.head_pipeline.run!
    end

    it 'sends polling interval' do
      expect(::Gitlab::PollingInterval).to receive(:set_header)

      subject
    end

    it 'returns 204 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end
end

RSpec.shared_examples 'comparable report' do
  context 'when comparison is being processed' do
    let(:comparison_status) { { status: :parsing } }

    it 'sends polling interval' do
      expect(::Gitlab::PollingInterval).to receive(:set_header)

      subject
    end

    it 'returns 204 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  context 'when comparison is done' do
    let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

    it 'does not send polling interval' do
      expect(::Gitlab::PollingInterval).not_to receive(:set_header)

      subject
    end

    it 'returns 200 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
    end
  end

  context 'when user created corrupted reports' do
    let(:comparison_status) { { status: :error, status_reason: 'Report parsing error' } }

    it 'does not send polling interval' do
      expect(::Gitlab::PollingInterval).not_to receive(:set_header)

      subject
    end

    it 'returns 400 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq({ 'status_reason' => 'Report parsing error' })
    end
  end
end

RSpec.describe Projects::MergeRequestsController do
  include ProjectForksHelper

  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be(:author) { create(:user) }

  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: author) }
  let(:user) { project.creator }
  let(:viewer) { user }

  before do
    stub_licensed_features(security_dashboard: true)
    sign_in(viewer)
  end

  describe 'PUT update', feature_category: :code_review_workflow do
    let_it_be_with_reload(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, author: author)
    end

    before do
      project.update!(approvals_before_merge: 2)
    end

    def update_merge_request(params = {})
      post :update,
        params: {
          namespace_id: merge_request.target_project.namespace.to_param,
          project_id: merge_request.target_project.to_param,
          id: merge_request.iid,
          merge_request: params
        }
    end

    context 'when the merge request requires approval' do
      before do
        project.update!(approvals_before_merge: 1)
      end

      it_behaves_like 'update invalid issuable', MergeRequest
    end

    context 'overriding approvers per MR' do
      before do
        project.update!(approvals_before_merge: 1)
      end

      context 'enabled' do
        before do
          project.update!(disable_overriding_approvers_per_merge_request: false)
        end

        it 'updates approvals' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(2)
        end

        it 'does not allow approvels before merge lower than the project setting' do
          update_merge_request(approvals_before_merge: 0)

          expect(merge_request.reload.approvals_before_merge).to eq(1)
        end

        it 'creates rules' do
          users = create_list(:user, 3)
          users.each { |user| project.add_developer(user) }

          update_merge_request(approval_rules_attributes: [
                                 { name: 'foo', user_ids: users.map(&:id), approvals_required: 3 }
                               ])

          expect(merge_request.reload.approval_rules.size).to eq(1)

          rule = merge_request.reload.approval_rules.first

          expect(rule.name).to eq('foo')
          expect(rule.approvals_required).to eq(3)
        end
      end

      context 'disabled' do
        let(:new_approver) { create(:user) }
        let(:new_approver_group) { create(:approver_group) }

        before do
          project.add_developer(new_approver)
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end

        it 'does not update approvals_before_merge' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(nil)
        end

        it 'does not update approver_ids' do
          update_merge_request(approver_ids: [new_approver].map(&:id).join(','))

          expect(merge_request.reload.approver_ids).to be_empty
        end

        it 'does not update approver_group_ids' do
          update_merge_request(approver_group_ids: [new_approver_group].map(&:id).join(','))

          expect(merge_request.reload.approver_group_ids).to be_empty
        end

        it 'does not create approval rules' do
          update_merge_request(
            approval_rules_attributes: [
              {
                name: 'Test',
                user_ids: [new_approver.id],
                approvals_required: 1
              }
            ]
          )

          expect(merge_request.reload.approval_rules).to be_empty
        end
      end
    end

    shared_examples 'approvals_before_merge param' do
      before do
        project.update!(approvals_before_merge: 2)
      end

      context 'approvals_before_merge not set for the existing MR' do
        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to the sames as the project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to the same as the project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end

      context 'approvals_before_merge set for the existing MR' do
        before do
          merge_request.update_attribute(:approvals_before_merge, 4)
        end

        context 'when it is not set' do
          before do
            update_merge_request(title: 'New title')
          end

          it 'does not change the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(4)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to the same as the target project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to the same as the target project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end
    end

    context 'when the MR targets the project' do
      it_behaves_like 'approvals_before_merge param'
    end

    context 'when the project is a fork' do
      let(:upstream) { create(:project, :repository) }
      let(:project) { fork_project(upstream, nil, repository: true) }

      context 'when the MR target upstream' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting upstream', source_project: project, target_project: upstream) }

        before do
          upstream.add_developer(user)
          upstream.update!(approvals_before_merge: 2)
        end

        it_behaves_like 'approvals_before_merge param'
      end

      context 'when the MR target the fork' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting the fork', source_project: project, target_project: project) }

        it_behaves_like 'approvals_before_merge param'
      end
    end
  end

  describe 'POST #rebase', feature_category: :code_review_workflow do
    def post_rebase
      post :rebase, params: { namespace_id: project.namespace, project_id: project, id: merge_request }
    end

    def expect_rebase_worker_for(user)
      allow(RebaseWorker).to receive(:with_status).and_return(RebaseWorker)
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, user.id, false)
    end

    context 'approvals pending' do
      let(:project) { create(:project, :repository, approvals_before_merge: 1) }

      it 'returns 200' do
        expect_rebase_worker_for(viewer)

        post_rebase

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET #edit', feature_category: :code_review_workflow do
    render_views

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :edit, params: params }

    context 'default templates' do
      let(:selected_field) { 'data-default="Default"' }
      let(:files) { { '.gitlab/merge_request_templates/Default.md' => '' } }
      let(:project) { create(:project, :custom_repo, files: files) }

      context 'when a merge request description has content' do
        let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: author, description: 'An existing description') }

        it 'does not select a default template' do
          subject

          expect(response.body).not_to include(selected_field)
        end
      end

      context 'when a merge request description is blank' do
        let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: author, description: '') }

        context 'when a default template does not exist in the repository' do
          let(:project) { create(:project) }

          it 'does not select a default template' do
            subject

            expect(response.body).not_to include(selected_field)
          end
        end

        context 'when a default template exists in the repository' do
          it 'does not select a default template' do
            subject

            expect(response.body).not_to include(selected_field)
          end
        end
      end
    end
  end

  describe 'GET #dependency_scanning_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :dependency_scanning_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'dependency_scanning').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #container_scanning_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_container_scanning_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :container_scanning_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'container_scanning').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #sast_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_sast_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :sast_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'sast').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #coverage_fuzzing_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_coverage_fuzzing_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :coverage_fuzzing_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'coverage_fuzzing').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #api_fuzzing_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_api_fuzzing_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :api_fuzzing_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'api_fuzzing').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #secret_detection_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_secret_detection_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid

      }
    end

    subject { get :secret_detection_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'secret_detection').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #dast_reports', feature_category: :vulnerability_management do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :dast_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareSecurityReportsService, viewer, 'dast').and_return(comparison_status)
      end
    end

    it_behaves_like 'pending pipeline response'
    it_behaves_like 'comparable report'
    it_behaves_like 'a security resource'
  end

  describe 'GET #license_scanning_reports', feature_category: :software_composition_analysis do
    let(:comparison_status) { { status: :parsed, data: { new_licenses: [], existing_licenses: [], removed_licenses: [] } } }
    let(:expected_response) { { "new_licenses" => [], "existing_licenses" => [], "removed_licenses" => [] } }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :license_scanning_reports, params: params, format: :json }

    before do
      stub_licensed_features(license_scanning: true)

      allow_next_found_instance_of(::MergeRequest) do |merge_request|
        allow(merge_request).to receive(:compare_reports)
                                  .with(::Ci::CompareLicenseScanningReportsService, viewer)
                                  .and_return(comparison_status)

        allow(merge_request).to receive(:has_denied_policies?).and_return(false)
      end
    end

    context 'when the license_scanning_sbom_scanner feature flag is false' do
      let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: project, author: author) }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      it_behaves_like 'license scanning report comparison', :with_license_scanning_reports
      it_behaves_like 'authorize read pipeline'
    end

    context 'when the license_scanning_sbom_scanner feature flag is true' do
      let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_cyclonedx_reports, source_project: project, author: author) }

      it_behaves_like 'license scanning report comparison', :with_cyclonedx_reports
      it_behaves_like 'authorize read pipeline'
    end
  end

  describe 'GET #license_scanning_reports_collapsed', feature_category: :software_composition_analysis do
    let(:comparison_status) { { status: :parsed, data: { new_licenses: 0, existing_licenses: 0, removed_licenses: 0 } } }
    let(:comparison_status_extended) { { status: :parsed, data: { new_licenses: [], existing_licenses: [], removed_licenses: [] } } }
    let(:expected_response) { { "new_licenses" => 0, "existing_licenses" => 0, "removed_licenses" => 0 } }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :license_scanning_reports_collapsed, params: params, format: :json }

    before do
      stub_licensed_features(license_scanning: true)

      allow_next_found_instance_of(::MergeRequest) do |merge_request|
        allow(merge_request).to receive(:compare_reports)
                                  .with(
                                    ::Ci::CompareLicenseScanningReportsCollapsedService,
                                    viewer,
                                    'license_scanning',
                                    { additional_params: { license_check: false } }
                                  )
                                  .and_return(comparison_status)

        allow(merge_request).to receive(:has_denied_policies?).and_return(false)
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is false" do
      let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: project, author: author) }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      it_behaves_like 'license scanning report comparison', :with_license_scanning_reports
      it_behaves_like 'authorize read pipeline'
    end

    context "when the license_scanning_sbom_scanner feature flag is true" do
      let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_cyclonedx_reports, source_project: project, author: author) }

      it_behaves_like 'license scanning report comparison', :with_cyclonedx_reports
      it_behaves_like 'authorize read pipeline'
    end
  end

  describe 'GET #metrics_reports', feature_category: :metrics do
    let_it_be_with_reload(:merge_request) { create(:ee_merge_request, :with_metrics_reports, source_project: project, author: author) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :metrics_reports, params: params, format: :json }

    before do
      allow_next_found_instance_of(::MergeRequest) do |instance|
        allow(instance).to receive(:compare_reports)
              .with(::Ci::CompareMetricsReportsService).and_return(comparison_status)
      end
    end

    it_behaves_like 'comparable report'
    it_behaves_like 'authorize read pipeline'
  end

  it_behaves_like DescriptionDiffActions do
    let_it_be(:project)  { create(:project, :repository, :public) }
    let_it_be(:issuable) { create(:merge_request, source_project: project) }
  end
end
