# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User with admin_merge_request custom role", feature_category: :code_review_workflow do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, :in_group) }
  let_it_be(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

  before do
    stub_licensed_features(custom_roles: true)

    sign_in(current_user)
  end

  describe Projects::MergeRequestsController do
    let_it_be(:role) { create(:member_role, :guest, namespace: project.group, admin_merge_request: true) }
    let_it_be(:member) { create(:project_member, :guest, member_role: role, user: current_user, project: project) }

    describe "#show" do
      it "user has access via a custom role" do
        get namespace_project_merge_request_path(
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end
  end
end
