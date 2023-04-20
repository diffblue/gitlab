# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let_it_be(:project, reload: true) { create(:project) }

  let_it_be(:public_project) { create(:project, :public, :repository, namespace: group) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'audit events with event type' do
    it 'logs the audit event' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(name: audit_name)
      ).and_call_original

      expect { request }.to change { AuditEvent.count }.by(1)
      expect(AuditEvent.last.details[:custom_message]).to eq(custom_message)
    end
  end

  describe 'GET new' do
    let_it_be(:params) { { namespace_id: user.namespace.id } }

    context 'when user does not have `:create_projects` permissions' do
      before do
        allow(controller).to receive(:can?).with(user, :create_projects, user.namespace).and_return(false)
      end

      it 'returns a 404' do
        get :new, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does have `:create_projects` permissions' do
      before do
        allow(controller).to receive(:can?).with(user, :create_projects, user.namespace).and_return(true)
      end

      it 'renders `new` template' do
        get :new, params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET show', feature_category: :projects do
    render_views

    subject { get :show, params: { namespace_id: public_project.namespace.path, id: public_project.path } }

    context 'additional repo storage by namespace' do
      let(:namespace) { public_project.namespace }

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        stub_feature_flags(namespace_storage_limit: false)

        namespace.add_owner(user)
      end

      context 'when automatic_purchased_storage_allocation setting is enabled' do
        before do
          stub_ee_application_setting(automatic_purchased_storage_allocation: true)
        end

        context 'when usage_ratio < 0.75' do
          before do
            allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage|
              allow(root_storage).to receive(:usage_ratio).and_return(0.5)
              allow(root_storage).to receive(:above_size_limit?).and_return(true)
            end
          end

          it 'does not include the CTA for additional purchased storage' do
            subject

            expect(response.body).not_to match(/Please purchase additional storage/)
          end
        end

        context 'when usage_ratio >= 0.75' do
          before do
            allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage|
              allow(root_storage).to receive(:usage_ratio).and_return(0.75)
              allow(root_storage).to receive(:above_size_limit?).and_return(true)
            end
          end

          it 'includes the CTA for additional purchased storage' do
            subject

            expect(response.body).to match(/Please purchase additional storage/)
          end
        end
      end

      context 'when automatic_purchased_storage_allocation setting is disabled' do
        before do
          stub_ee_application_setting(automatic_purchased_storage_allocation: false)
        end

        it 'does not include the CTA for additional purchased storage' do
          subject

          expect(response.body).not_to match(/Please purchase additional storage/)
        end
      end
    end

    context 'with automatic_purchased_storage_allocation set to true' do
      before do
        stub_ee_application_setting(automatic_purchased_storage_allocation: true)
      end

      it 'does not show over size limit warning when above_size_limit' do
        allow_next_instance_of(Gitlab::RepositorySizeChecker) do |checker|
          expect(checker).to receive(:above_size_limit?).and_return(true)
        end

        subject

        expect(response.body).not_to match(/The size of this repository.+exceeds the limit/)
      end
    end

    context 'with automatic_purchased_storage_allocation set to false' do
      before do
        stub_ee_application_setting(automatic_purchased_storage_allocation: false)
      end

      it 'shows the over size limit warning message if above_size_limit' do
        allow_next_instance_of(Gitlab::RepositorySizeChecker) do |checker|
          expect(checker).to receive(:above_size_limit?).and_return(true)
        end

        subject

        expect(response.body).to match(/The size of this repository.+exceeds the limit/)
      end

      it 'does not show an over size warning if not above_size_limit' do
        subject

        expect(response.body).not_to match(/The size of this repository.+exceeds the limit/)
      end
    end

    context 'namespace storage limit' do
      let(:namespace) { public_project.namespace }

      it_behaves_like 'namespace storage limit alert'

      it_behaves_like 'seat count alert'
    end
  end

  describe 'GET edit', feature_category: :projects do
    it 'does not allow an auditor user to access the page' do
      sign_in(create(:user, :auditor))

      get :edit, params: {
        namespace_id: project.namespace.path,
        id: project.path
      }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST create', feature_category: :projects do
    let!(:params) do
      {
        path: 'foo',
        description: 'bar',
        import_url: project.http_url_to_repo,
        namespace_id: user.namespace.id,
        visibility_level: Gitlab::VisibilityLevel::PUBLIC,
        mirror: true,
        mirror_trigger_builds: true
      }
    end

    context 'with licensed repository mirrors' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'has mirror enabled in new project' do
        post :create, params: { project: params }

        created_project = Project.find_by_path('foo')
        expect(created_project.reload.mirror).to be true
        expect(created_project.reload.mirror_user.id).to eq(user.id)
      end
    end

    context 'with unlicensed repository mirrors' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'has mirror disabled in new project' do
        post :create, params: { project: params }

        created_project = Project.find_by_path('foo')
        expect(created_project.reload.mirror).to be false
        expect(created_project.reload.mirror_user).to be nil
      end
    end

    context 'built in project templates' do
      let(:templates_params) do
        {
          path: 'foo',
          description: 'bar',
          namespace_id: user.namespace.id,
          template_name: 'rails'
        }
      end

      it 'creates one audit event' do
        expect { post :create, params: { project: templates_params } }.to change { AuditEvent.count }.by(1)
      end
    end

    context 'custom project templates' do
      let(:project_template) { create(:project, :repository, :public, :metrics_dashboard_enabled, namespace: group) }
      let(:templates_params) do
        {
          path: 'foo',
          description: 'bar',
          namespace_id: user.namespace.id,
          use_custom_template: true,
          template_name: project_template.name
        }
      end

      context 'when licensed' do
        before do
          stub_licensed_features(custom_project_templates: true)
          stub_ee_application_setting(custom_project_templates_group_id: group.id)
        end

        context 'object storage' do
          before do
            stub_uploads_object_storage(FileUploader)
          end

          it 'creates the project from project template', :sidekiq_might_not_need_inline do
            post :create, params: { project: templates_params }

            created_project = Project.find_by_path('foo')
            expect(flash[:notice]).to eq "Project 'foo' was successfully created."
            expect(created_project.repository.empty?).to be false
          end
        end
      end

      context 'when unlicensed' do
        render_views

        before do
          stub_licensed_features(custom_project_templates: false)
          project
          project_template
        end

        it 'does not create the project from project template' do
          expect { post :create, params: { project: templates_params } }.not_to change { Project.count }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to match(/Template name .* is unknown or invalid/)
        end
      end
    end
  end

  describe 'PUT #update', feature_category: :projects do
    it 'updates EE attributes' do
      params = {
        repository_size_limit: 1024
      }

      put :update, params: {
        namespace_id: project.namespace,
        id: project,
        project: params
      }
      project.reload

      expect(response).to have_gitlab_http_status(:found)
      params.except(:repository_size_limit).each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
      expect(project.repository_size_limit).to eq(params[:repository_size_limit].megabytes)
    end

    it 'updates Merge Request Approvers attributes' do
      params = {
        approvals_before_merge: 50,
        approver_group_ids: create(:group).id,
        approver_ids: create(:user).id,
        reset_approvals_on_push: false
      }

      put :update, params: {
        namespace_id: project.namespace,
        id: project,
        project: params
      }
      project.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(project.approver_groups.pluck(:group_id)).to contain_exactly(params[:approver_group_ids])
      expect(project.approvers.pluck(:user_id)).to contain_exactly(params[:approver_ids])
    end

    it 'updates Issuable Default Templates attributes' do
      params = {
        issues_template: 'You got issues?',
        merge_requests_template: 'I got tissues'
      }

      put :update, params: {
        namespace_id: project.namespace,
        id: project,
        project: params
      }
      project.reload

      expect(response).to have_gitlab_http_status(:found)
      params.each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
    end

    it 'updates cve_id_request_enabled' do
      project.project_setting.cve_id_request_enabled = false
      project.project_setting.save!

      params = {
        project_setting_attributes: {
          cve_id_request_enabled: true
        }
      }
      put :update,
        params: {
        namespace_id: project.namespace,
        id: project,
        project: params
      }
      project.reload

      expect(project.project_setting.cve_id_request_enabled).to eq(true)
    end

    context 'when merge_pipelines_enabled param is specified' do
      let(:params) { { merge_pipelines_enabled: true } }

      let(:request) do
        put :update, params: { namespace_id: project.namespace, id: project, project: params }
      end

      before do
        stub_licensed_features(merge_pipelines: true)
      end

      it 'updates the attribute' do
        request

        expect(project.reload.merge_pipelines_enabled).to be_truthy
      end

      context 'when license is not sufficient' do
        before do
          stub_licensed_features(merge_pipelines: false)
        end

        it 'does not update the attribute' do
          request

          expect(project.reload.merge_pipelines_enabled).to be_falsy
        end
      end
    end

    context 'when only_allow_merge_if_all_status_checks_passed param is specified' do
      let(:params) { { project_setting_attributes: { only_allow_merge_if_all_status_checks_passed: true } } }

      let(:request) do
        put :update, params: { namespace_id: project.namespace, id: project, project: params }
      end

      it_behaves_like 'update only allow merge if all status checks passed'
    end

    context 'when merge_trains_enabled param is specified' do
      let(:params) { { merge_trains_enabled: true } }

      let(:request) do
        put :update, params: { namespace_id: project.namespace, id: project, project: params }
      end

      before do
        stub_licensed_features(merge_pipelines: true, merge_trains: true)
      end

      it 'updates the attribute' do
        request

        expect(project.merge_trains_enabled).to be_truthy
      end

      context 'when license is not sufficient' do
        before do
          stub_licensed_features(merge_trains: false)
        end

        it 'does not update the attribute' do
          request

          expect(project.merge_trains_enabled).to be_falsy
        end
      end
    end

    context 'when auto_rollback_enabled param is specified' do
      let(:params) { { auto_rollback_enabled: true } }

      let(:request) do
        put :update, params: { namespace_id: project.namespace, id: project, project: params }
      end

      before do
        stub_licensed_features(auto_rollback: true)
      end

      it 'updates the attribute' do
        request

        expect(project.reload.auto_rollback_enabled).to be_truthy
      end

      context 'when license is not sufficient' do
        before do
          stub_licensed_features(auto_rollback: false)
        end

        it 'does not update the attribute' do
          request

          expect(project.reload.auto_rollback_enabled).to be_falsy
        end
      end
    end

    context 'repository mirrors' do
      let(:params) do
        {
          mirror: true,
          mirror_trigger_builds: true,
          import_url: 'https://example.com'
        }
      end

      context 'when licensed' do
        before do
          stub_licensed_features(repository_mirrors: true)
        end

        it 'updates repository mirror attributes' do
          expect(UpdateAllMirrorsWorker).to receive(:perform_async)

          put :update,
            params: {
              namespace_id: project.namespace,
              id: project,
              project: params
            }
          project.reload

          expect(project.mirror).to eq(true)
          expect(project.mirror_trigger_builds).to eq(true)
          expect(project.mirror_user).to eq(user)
          expect(project.import_url).to eq('https://example.com')
        end

        it 'ignores mirror_user_id' do
          other_user = create(:user)

          put :update,
            params: {
              namespace_id: project.namespace,
              id: project,
              project: params.merge(mirror_user_id: other_user.id)
            }
          project.reload

          expect(project.mirror_user).to eq(user)
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(repository_mirrors: false)
        end

        it 'does not update repository mirror attributes' do
          params.each do |param, _value|
            expect do
              put :update,
                params: {
                  namespace_id: project.namespace,
                  id: project,
                  project: params
                }
              project.reload
            end.not_to change(project, param)
          end
        end
      end
    end

    context 'merge request approvers settings' do
      shared_examples 'merge request approvers rules' do
        using RSpec::Parameterized::TableSyntax

        where(:can_modify, :param_value, :final_value) do
          true  | true  | true
          true  | false | false
          false | true  | nil
          false | false | nil
        end

        with_them do
          before do
            allow(controller).to receive(:can?).and_call_original
            allow(controller).to receive(:can?).with(user, rule_name, project).and_return(can_modify)
          end

          it 'updates project if needed' do
            put :update,
              params: {
                namespace_id: project.namespace,
                id: project,
                project: { setting => param_value }
              }

            project.reload

            expect(project[setting]).to eq(final_value.nil? ? setting_default_value : final_value)
          end
        end
      end

      describe ':disable_overriding_approvers_per_merge_request' do
        it_behaves_like 'merge request approvers rules' do
          let(:rule_name) { :modify_approvers_rules }
          let(:setting) { :disable_overriding_approvers_per_merge_request }
          let(:setting_default_value) { nil }
        end
      end

      describe ':merge_requests_author_approval' do
        it_behaves_like 'merge request approvers rules' do
          let(:rule_name) { :modify_merge_request_author_setting }
          let(:setting) { :merge_requests_author_approval }
          let(:setting_default_value) { false }
        end
      end

      describe ':merge_requests_disable_committers_approval' do
        it_behaves_like 'merge request approvers rules' do
          let(:rule_name) { :modify_merge_request_committer_setting }
          let(:setting) { :merge_requests_disable_committers_approval }
          let(:setting_default_value) { nil }
        end
      end
    end

    context 'analytics dashboards pointer setting' do
      let_it_be(:project, reload: true) { create(:project, namespace: group) }
      let_it_be(:another_project) do
        create(:project, namespace: group).tap { |p| p.add_maintainer(user) }
      end

      let(:params) do
        {
          id: project,
          namespace_id: project.namespace,
          project: {
            analytics_dashboards_pointer_attributes: { target_project_id: another_project.id }
          }
        }
      end

      context 'without correct license' do
        before do
          stub_licensed_features(project_level_analytics_dashboard: false)

          put :update, params: params
        end

        it 'ignores input' do
          expect(project.analytics_dashboards_configuration_project).to be_nil
        end
      end

      context 'with correct license' do
        before do
          stub_licensed_features(project_level_analytics_dashboard: true)

          put :update, params: params
        end

        it 'updates analytics dashboards configuration project' do
          expect(project.analytics_dashboards_configuration_project).to eq another_project
        end
      end
    end

    context 'compliance framework settings' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }

      shared_examples 'no compliance framework is set' do
        it 'does not change compliance framework for project' do
          put :update, params: {
            namespace_id: project.group,
            id: project,
            project: params
          }
          project.reload

          expect(project.compliance_framework_setting).to be_nil
        end
      end

      context 'when unlicensed' do
        let(:framework) { create(:compliance_framework, namespace: project.group.root_ancestor) }
        let(:params) { { compliance_framework_setting_attributes: { framework: framework.id } } }

        before do
          stub_licensed_features(compliance_framework: false)
        end

        it_behaves_like 'no compliance framework is set'
      end

      context 'when licensed' do
        let(:framework) { create(:compliance_framework, namespace: project.group.root_ancestor) }
        let(:params) { { compliance_framework_setting_attributes: { framework: framework.id } } }

        before do
          stub_licensed_features(compliance_framework: true)
          project.add_owner(user)
        end

        context 'current_user is a project owner' do
          before do
            sign_in(user)
          end

          it 'sets the compliance framework' do
            put :update, params: {
              namespace_id: project.group,
              id: project,
              project: params
            }
            project.reload

            expect(project.compliance_framework_setting.compliance_management_framework).to eq(framework)
          end
        end
      end
    end
  end

  describe '#download_export', feature_category: :importers do
    let(:request) { get :download_export, params: { namespace_id: project.namespace, id: project } }

    context 'when project export is enabled' do
      it_behaves_like 'audit events with event type' do
        let_it_be(:audit_name) { 'project_export_file_download_started' }
        let_it_be(:custom_message) { 'Export file download started' }
      end
    end

    context 'when project export is disabled' do
      before do
        stub_ee_application_setting(project_export_enabled?: false)
      end

      it 'does not log an audit event' do
        expect { request }.not_to change { AuditEvent.count }
      end
    end
  end

  context 'Archive & Unarchive actions', feature_category: :projects do
    let(:project) { create(:project, group: group) }
    let(:archived_project) { create(:project, :archived, group: group) }

    describe 'POST #archive' do
      let(:request) { post :archive, params: { namespace_id: project.namespace, id: project } }

      context 'for a user with the ability to archive a project' do
        before do
          group.add_owner(user)
        end

        it_behaves_like 'audit events with event type' do
          let_it_be(:audit_name) { 'project_archived' }
          let_it_be(:custom_message) { 'Project archived' }
        end
      end

      context 'for a user that does not have the ability to archive a project' do
        before do
          project.add_maintainer(user)
        end

        it 'does not log the audit event' do
          expect { request }.not_to change { AuditEvent.count }
        end
      end
    end

    describe 'POST #unarchive' do
      let(:request) { post :unarchive, params: { namespace_id: archived_project.namespace, id: archived_project } }

      context 'for a user with the ability to unarchive a project' do
        before do
          group.add_owner(user)
        end

        it_behaves_like 'audit events with event type' do
          let_it_be(:audit_name) { 'project_unarchived' }
          let_it_be(:custom_message) { 'Project unarchived' }
        end
      end

      context 'for a user that does not have the ability to unarchive a project' do
        before do
          project.add_maintainer(user)
        end

        it 'does not log the audit event' do
          expect { request }.not_to change { AuditEvent.count }
        end
      end
    end
  end

  describe 'DELETE #destroy', feature_category: :projects do
    let(:project) { create(:project, group: group) }

    before do
      group.add_member(user, Gitlab::Access::OWNER)
      controller.instance_variable_set(:@project, project)
      sign_in(user)
    end

    shared_examples 'deletes project right away' do
      it do
        delete :destroy, params: { namespace_id: project.namespace, id: project }

        expect(project.marked_for_deletion?).to be_falsey
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(dashboard_projects_path)
      end
    end

    shared_examples 'marks project for deletion' do
      it do
        delete :destroy, params: { namespace_id: project.namespace, id: project }

        expect(project.reload.marked_for_deletion?).to be_truthy
        expect(project.reload.hidden?).to be_falsey
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(project_path(project))
      end
    end

    shared_examples 'marks free project for deletion' do
      it do
        delete :destroy, params: { namespace_id: project.namespace, id: project }

        expect(project.reload.marked_for_deletion?).to be_truthy
        expect(project.reload.marked_for_deletion_at).to be_truthy
        expect(project.reload.hidden?).to be_truthy
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(dashboard_projects_path)
      end
    end

    context 'feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'when feature is enabled for group' do
        before do
          allow(group.namespace_settings).to receive(:delayed_project_removal?).and_return(true)
        end

        it_behaves_like 'marks project for deletion'

        it 'does not mark project for deletion because of error' do
          message = 'Error'

          expect(::Projects::MarkForDeletionService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: message })

          delete :destroy, params: { namespace_id: project.namespace, id: project }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
          expect(flash[:alert]).to include(message)
        end

        context 'when instance setting is set to 0 days' do
          it 'deletes project right away' do
            stub_ee_application_setting(deletion_adjourned_period: 0)

            delete :destroy, params: { namespace_id: project.namespace, id: project }

            expect(project.marked_for_deletion?).to be_falsey
            expect(response).to have_gitlab_http_status(:found)
            expect(response).to redirect_to(dashboard_projects_path)
          end
        end

        context 'when project is already marked for deletion' do
          let(:project) { create(:project, group: group, marked_for_deletion_at: Date.current) }

          context 'when permanently_delete param is set' do
            it 'deletes project right away' do
              expect(ProjectDestroyWorker).to receive(:perform_async)

              delete :destroy, params: { namespace_id: project.namespace, id: project, permanently_delete: true }

              expect(project.reload.pending_delete).to eq(true)
              expect(response).to have_gitlab_http_status(:found)
              expect(response).to redirect_to(dashboard_projects_path)
            end
          end

          context 'when permanently_delete param is not set' do
            it 'does nothing' do
              expect(ProjectDestroyWorker).not_to receive(:perform_async)

              delete :destroy, params: { namespace_id: project.namespace, id: project }

              expect(project.reload.pending_delete).to eq(false)
              expect(response).to have_gitlab_http_status(:found)
              expect(response).to redirect_to(project_path(project))
            end
          end
        end
      end

      context 'when feature is disabled for group' do
        before do
          allow(group.namespace_settings).to receive(:delayed_project_removal?).and_return(false)
        end

        context 'when `always_perform_delayed_deletion` is disabled' do
          before do
            stub_feature_flags(always_perform_delayed_deletion: false)
          end

          it_behaves_like 'deletes project right away'
        end

        context 'when `always_perform_delayed_deletion` is enabled' do
          it_behaves_like 'marks project for deletion'
        end
      end

      context 'when feature is not available for the project' do
        before do
          allow(group.namespace_settings).to receive(:delayed_project_removal?).and_return(true)
          allow(project).to receive(:licensed_feature_available?).and_call_original
          allow(project).to receive(:licensed_feature_available?).with(:adjourned_deletion_for_projects_and_groups).and_return(false)
          allow(project).to receive(:feature_available?).and_call_original
          allow(project).to receive(:feature_available?).with(:adjourned_deletion_for_projects_and_groups).and_return(false)
        end

        it_behaves_like 'marks free project for deletion'
      end

      context 'for projects in user namespace' do
        let(:project) { create(:project, namespace: user.namespace) }

        it_behaves_like 'deletes project right away'
      end
    end

    context 'feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it_behaves_like 'deletes project right away'
    end
  end

  describe 'POST #restore', feature_category: :projects do
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      sign_in(user)
    end

    it 'restores project deletion' do
      post :restore, params: { namespace_id: project.namespace, project_id: project }

      expect(project.reload.marked_for_deletion_at).to be_nil
      expect(project.reload.archived).to be_falsey
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(edit_project_path(project))
    end

    it 'does not restore project because of error' do
      message = 'Error'
      expect(::Projects::RestoreService).to receive_message_chain(:new, :execute).and_return({ status: :error, message: message })

      post :restore, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:edit)
      expect(flash[:alert]).to include(message)
    end
  end
end
