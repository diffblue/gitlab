# frozen_string_literal: true
require "spec_helper"

RSpec.describe Projects::ProtectedBranchesController, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:protected_branch) { create(:protected_branch, project: project) }
  let(:project_params) { { namespace_id: project.namespace.to_param, project_id: project } }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
  end

  shared_examples "protected branch with code owner approvals feature" do |boolean|
    it "sets code owner approvals to #{boolean} when protecting the branch" do
      expect do
        post(:create, params: project_params.merge(protected_branch: create_params))
      end.to change { ProtectedBranch.count }.by(1)

      expect(ProtectedBranch.last.attributes["code_owner_approval_required"]).to eq(boolean)
    end
  end

  describe "POST #create" do
    let(:maintainer_access_level) { [{ access_level: Gitlab::Access::MAINTAINER }] }
    let(:access_level_params) do
      { merge_access_levels_attributes: maintainer_access_level,
        push_access_levels_attributes: maintainer_access_level }
    end

    let(:create_params) do
      attributes_for(:protected_branch).merge(access_level_params)
    end

    before do
      sign_in(user)
    end

    context "when code_owner_approval_required is 'false'" do
      before do
        create_params[:code_owner_approval_required] = false
      end

      it_behaves_like "protected branch with code owner approvals feature", false
    end

    context "when code_owner_approval_required is 'true'" do
      before do
        create_params[:code_owner_approval_required] = true
      end

      context "when the feature is enabled" do
        before do
          stub_licensed_features(code_owner_approval_required: true)
        end

        it_behaves_like "protected branch with code owner approvals feature", true
      end

      context "when the feature is not enabled" do
        before do
          stub_licensed_features(code_owner_approval_required: false)
        end

        it_behaves_like "protected branch with code owner approvals feature", false
      end
    end
  end
end
