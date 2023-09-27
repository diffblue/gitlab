# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Branches, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user, path: 'my.project') }
  let_it_be(:protected_branch) { create(:protected_branch, project: project) }

  before_all do
    project.add_maintainer(user)
    project.repository.add_branch(user, protected_branch.name, 'master')
  end

  describe 'PUT /projects/:id/repository/branches/:branch/protect' do
    subject(:protect) do
      put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
          params: { developers_can_push: true, developers_can_merge: true }
    end

    context "when no one can push" do
      before do
        protected_branch.push_access_levels.create!(access_level: Gitlab::Access::NO_ACCESS)
      end

      it "updates 'developers_can_push' without removing the 'no_one' access level" do
        protect

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(protected_branch.name)
        expect(protected_branch.reload.push_access_levels.pluck(:access_level)).to include(Gitlab::Access::NO_ACCESS)
      end

      context 'with blocking scan result policy' do
        include_context 'with scan result policy blocking protected branches' do
          let(:branch_name) { protected_branch.name }
          let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: protected_branch.project) }

          it 'blocks unprotecting branches' do
            protect

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id/repository/branches/:branch/unprotect' do
    subject(:unprotect) do
      put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/unprotect", user)
    end

    context 'with blocking scan result policy' do
      include_context 'with scan result policy blocking protected branches' do
        let(:branch_name) { protected_branch.name }
        let(:policy_configuration) do
          create(:security_orchestration_policy_configuration, project: protected_branch.project)
        end

        it 'blocks unprotecting branches' do
          unprotect

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end
end
