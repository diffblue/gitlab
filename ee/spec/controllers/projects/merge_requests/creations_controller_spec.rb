# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::CreationsController, feature_category: :code_review_workflow do
  let(:project)       { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:user)          { project.first_owner }
  let(:viewer)        { user }

  before do
    sign_in(viewer)
  end

  describe 'GET #new' do
    render_views

    context 'default templates' do
      let(:selected_field) { 'data-default="Default"' }
      let(:files) { { '.gitlab/merge_request_templates/Default.md' => '' } }

      subject do
        get :new, params: {
          namespace_id: project.namespace,
          project_id: project,
          merge_request: {
            source_project_id: project.id,
            source_branch: 'feature',
            target_project_id: project.id,
            target_branch: 'master'
          }
        }
      end

      before do
        project.repository.create_branch('feature', 'master')
      end

      context 'when a template has been set via project settings' do
        let(:project) { create(:project, :custom_repo, merge_requests_template: 'Content', files: files) }

        it 'does not select a default template' do
          subject

          expect(response.body).not_to include(selected_field)
        end
      end

      context 'when a template has not been set via project settings' do
        let(:project) { create(:project, :custom_repo, files: files) }

        it 'selects a default template' do
          subject

          expect(response.body).to include(selected_field)
        end
      end
    end
  end

  describe 'POST #create' do
    let(:created_merge_request) { assigns(:merge_request) }

    def create_merge_request(overrides = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        merge_request: {
          title: 'Test',
          source_branch: 'feature_conflict',
          target_branch: 'master',
          author: user
        }.merge(overrides)
      }

      post :create, params: params
    end

    context 'the approvals_before_merge param' do
      before do
        project.update!(approvals_before_merge: 2)
      end

      context 'when it is less than the one in the target project' do
        before do
          create_merge_request(approvals_before_merge: 1)
        end

        it 'sets the param to the project value' do
          expect(created_merge_request.reload.approvals_before_merge).to eq(2)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end

      context 'when it is equal to the one in the target project' do
        before do
          create_merge_request(approvals_before_merge: 2)
        end

        it 'sets the param to the correct value' do
          expect(created_merge_request.reload.approvals_before_merge).to eq(2)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end

      context 'when it is greater than the one in the target project' do
        before do
          create_merge_request(approvals_before_merge: 3)
        end

        it 'saves the param in the merge request' do
          expect(created_merge_request.approvals_before_merge).to eq(3)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end

      context 'when the target project is a fork of a deleted project' do
        before do
          original_project = create(:project)
          project.update!(forked_from_project: original_project, approvals_before_merge: 4)
          original_project.update!(pending_delete: true)

          create_merge_request(approvals_before_merge: 3)
        end

        it 'uses the default from the target project' do
          expect(created_merge_request.reload.approvals_before_merge).to eq(4)
        end

        it 'creates the merge request' do
          expect(created_merge_request).to be_valid
          expect(response).to redirect_to(project_merge_request_path(project, created_merge_request))
        end
      end
    end

    context 'overriding approvers per MR' do
      let(:new_approver) { create(:user) }

      before do
        project.add_developer(new_approver)
        project.update!(disable_overriding_approvers_per_merge_request: disable_overriding_approvers_per_merge_request)

        create_merge_request(
          approval_rules_attributes: [
            {
              name: 'Test',
              user_ids: [new_approver.id],
              approvals_required: 1
            }
          ]
        )
      end

      context 'enabled' do
        let(:disable_overriding_approvers_per_merge_request) { false }

        it 'does create approval rules' do
          approval_rules = created_merge_request.reload.approval_rules

          expect(approval_rules.count).to eq(1)
          expect(approval_rules.first.name).to eq('Test')
          expect(approval_rules.first.user_ids).to eq([new_approver.id])
          expect(approval_rules.first.approvals_required).to eq(1)
        end
      end

      context 'disabled' do
        let(:disable_overriding_approvers_per_merge_request) { true }

        it 'does not create approval rules' do
          expect(created_merge_request.reload.approval_rules).to be_empty
        end
      end
    end

    it 'disables query limiting' do
      expect(Gitlab::QueryLimiting).to receive(:disable!)

      create_merge_request
    end
  end
end
