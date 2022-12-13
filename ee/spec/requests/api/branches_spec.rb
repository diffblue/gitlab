# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Branches, feature_category: :source_code_management do
  describe 'PUT /projects/:id/repository/branches/:branch/protect' do
    context 'when authenticated', 'as a maintainer' do
      let(:user) { create(:user) }
      let(:project) { create(:project, :repository, creator: user, path: 'my.project') }

      before do
        project.add_maintainer(user)
      end

      context 'when protected branch already exists' do
        before do
          project.repository.add_branch(user, protected_branch.name, 'master')
        end

        context "when no one can push" do
          let(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project, name: 'protected_branch') }

          it "updates 'developers_can_push' without removing the 'no_one' access level" do
            put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
                params: { developers_can_push: true, developers_can_merge: true }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['name']).to eq(protected_branch.name)
            expect(protected_branch.reload.push_access_levels.pluck(:access_level)).to include(Gitlab::Access::NO_ACCESS)
          end
        end
      end
    end
  end
end
