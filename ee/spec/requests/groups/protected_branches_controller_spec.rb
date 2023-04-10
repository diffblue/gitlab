# frozen_string_literal: true

require('spec_helper')

RSpec.describe Groups::ProtectedBranchesController, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:protected_branch) { create(:protected_branch, group: group, project: nil) }
  let(:collection_path) { group_protected_branches_path(group_id: group) }
  let(:member_path) { group_protected_branch_path(group_id: group, id: protected_branch.id) }

  before do
    stub_licensed_features(group_protected_branches: true)
    group.add_owner(user)
    sign_in(user)
  end

  describe 'before action hook' do
    context 'when group is not top-level' do
      let(:group) { create(:group, :nested) }

      it 'respond status :not_found' do
        post collection_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature flag disabled' do
      before do
        stub_feature_flags(group_protected_branches: false)
        stub_feature_flags(allow_protected_branches_for_group: false)
      end

      it 'respond status :not_found' do
        post collection_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when license disabled' do
      before do
        stub_licensed_features(group_protected_branches: false)
      end

      it 'respond status :not_found' do
        post collection_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when cannot admin group' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :admin_group, group).and_return(false)
      end

      it 'respond status :not_found' do
        post collection_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    let(:maintainer_access_level) { [{ access_level: Gitlab::Access::MAINTAINER }] }
    let(:access_level_params) do
      {
        merge_access_levels_attributes: maintainer_access_level,
        push_access_levels_attributes: maintainer_access_level
      }
    end

    let(:create_params) { { protected_branch: { name: 'protected_branch' }.merge(access_level_params) } }

    describe 'creates the protected branch rule' do
      let(:headers) { {} }

      subject { post collection_path, params: create_params, headers: headers }

      context 'when format :html' do
        it 'added record and response :found' do
          expect { subject }.to change { ProtectedBranch.count }.by(1)
          expect(response).to have_gitlab_http_status(:found)
        end
      end

      context 'when format :json' do
        let(:headers) { { "ACCEPT" => "application/json" } }

        it 'added record and response :ok' do
          expect { subject }.to change { ProtectedBranch.count }.by(1)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when a policy restricts rule creation' do
      before do
        disallow(:create_protected_branch, an_instance_of(ProtectedBranch))
      end

      it "prevents creation of the protected branch rule" do
        expect do
          post collection_path, params: create_params
        end.not_to change { ProtectedBranch.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "PUT #update" do
    let(:update_params) { { protected_branch: { name: 'new_name' } } }

    it 'updates the protected branch rule' do
      patch member_path, params: update_params

      expect(protected_branch.reload.name).to eq('new_name')
      expect(json_response["name"]).to eq('new_name')
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when a policy restricts rule update' do
      before do
        disallow(:update_protected_branch, an_instance_of(ProtectedBranch))
      end

      it "prevents update of the protected branch rule" do
        expect { patch member_path, params: update_params }.not_to change { protected_branch.reload.name }
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when a invalid value update' do
      let(:update_params) { { protected_branch: { name: nil } } }

      it "prevents update of the protected branch rule" do
        expect { patch member_path, params: update_params }.not_to change { protected_branch.reload.name }
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "deletes the protected branch rule" do
      delete member_path

      expect { protected_branch.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to have_gitlab_http_status(:found)
    end

    context 'when a policy restricts rule deletion' do
      before do
        disallow(:destroy_protected_branch, an_instance_of(ProtectedBranch))
      end

      it "prevents deletion of the protected branch rule" do
        delete member_path

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  private

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
