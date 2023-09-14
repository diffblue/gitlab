# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User with admin_merge_request custom role', feature_category: :code_review_workflow do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :in_group) }
  let_it_be(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
  let_it_be(:role) { create(:member_role, :guest, namespace: project.group, admin_merge_request: true) }
  let_it_be(:membership) { create(:project_member, :guest, member_role: role, user: current_user, project: project) }

  before do
    stub_licensed_features(custom_roles: true)

    sign_in(current_user)
  end

  describe Projects::MergeRequestsController do
    describe '#show' do
      shared_examples_for 'allows viewing the MR with custom role' do |project_visibility:|
        before do
          project.update!(visibility: project_visibility)
        end

        it 'user has access via a custom role' do
          get namespace_project_merge_request_path(
            namespace_id: project.namespace.to_param,
            project_id: project,
            id: merge_request.iid
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context 'when the project is public' do
        it_behaves_like 'allows viewing the MR with custom role', project_visibility: Gitlab::VisibilityLevel::PUBLIC
      end

      context 'when the project is private' do
        it_behaves_like 'allows viewing the MR with custom role', project_visibility: Gitlab::VisibilityLevel::PRIVATE

        context 'when the "Merge Requests" feature is set as private' do
          before do
            project.project_feature.update_column(:merge_requests_access_level, ProjectFeature::PRIVATE)
          end

          it_behaves_like 'allows viewing the MR with custom role',
            project_visibility: Gitlab::VisibilityLevel::PRIVATE
        end
      end
    end
  end
end
