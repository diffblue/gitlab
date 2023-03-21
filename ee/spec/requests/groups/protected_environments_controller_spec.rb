# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Groups::ProtectedEnvironmentsController, feature_category: :continuous_delivery do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup_1) { create(:group, parent: group) }
  let_it_be(:subgroup_2) { create(:group, parent: group) }
  let_it_be(:subgroup_3) { create(:group, parent: group) }
  let_it_be(:group_owner) { create(:user).tap { |u| group.add_owner(u) } }
  let_it_be(:group_maintainer) { create(:user).tap { |u| group.add_maintainer(u) } }

  let(:current_user) { group_owner }

  before do
    sign_in(current_user)
  end

  describe '#POST create' do
    let(:params) do
      attributes_for(:protected_environment,
        name: 'production',
        deploy_access_levels_attributes: [{ group_id: subgroup_1.id }])
    end

    subject do
      post group_protected_environments_path(group_id: group), params: { protected_environment: params }, as: :json
    end

    context 'with valid params' do
      it 'creates a new ProtectedEnvironment' do
        expect { subject }.to change(ProtectedEnvironment, :count).by(1)
      end

      it 'sets a flash' do
        subject

        expect(flash[:notice]).to match(/environment has been protected/)
      end

      it 'redirects to CI/CD settings' do
        subject

        expect(response).to redirect_to group_settings_ci_cd_path(group, anchor: 'js-protected-environments-settings')
      end
    end

    context 'with invalid params' do
      let(:params) do
        attributes_for(:protected_environment,
                        name: '',
                        deploy_access_levels_attributes: [{ group_id: subgroup_1.id }])
      end

      it 'does not create a new ProtectedEnvironment' do
        expect { subject }.not_to change(ProtectedEnvironment, :count)
      end

      it 'redirects to CI/CD settings' do
        subject

        expect(response).to redirect_to group_settings_ci_cd_path(group, anchor: 'js-protected-environments-settings')
      end
    end

    context 'with invalid access' do
      let(:current_user) { group_maintainer }

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#PUT update' do
    let(:protected_environment) do
      create(:protected_environment, :group_level, group: group, authorize_group_to_deploy: subgroup_1)
    end

    let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

    let(:params) do
      {
        deploy_access_levels_attributes: [
          { id: deploy_access_level.id, group_id: subgroup_2.id },
          { group_id: subgroup_3.id }
        ]
      }
    end

    subject do
      put group_protected_environment_path(group_id: group, id: protected_environment.id),
          params: { protected_environment: params }, as: :json
    end

    it 'updates the protected environment', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)

      new_group_ids = json_response['deploy_access_levels'].map { |level| level['group_id'] }

      expect(new_group_ids).to match_array([subgroup_2.id, subgroup_3.id])
    end

    context 'with invalid params' do
      let(:params) { attributes_for(:protected_environment, name: '') }

      it 'returns unprocessable_entity' do
        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['errors'])
          .to eq("Name can't be blank and " \
                 "Name must be one of environment tiers: production, staging, testing, development, other.")
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { group_maintainer }

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#DELETE destroy' do
    let!(:protected_environment) { create(:protected_environment, :group_level, group: group) }

    subject do
      delete group_protected_environment_path(group_id: group, id: protected_environment.id)
    end

    it 'finds the requested protected environment' do
      subject

      expect(assigns(:protected_environment)).to eq(protected_environment)
    end

    it 'deletes the requested protected environment' do
      expect { subject }.to change { ProtectedEnvironment.count }.from(1).to(0)
    end

    it 'redirects to CI/CD settings' do
      subject

      expect(response).to redirect_to group_settings_ci_cd_path(group, anchor: 'js-protected-environments-settings')
    end

    context 'when destroy failed' do
      before do
        allow_next_instance_of(::ProtectedEnvironments::DestroyService) do |service|
          allow(service).to receive(:execute) { false }
        end
      end

      it 'sets a flash' do
        expect { subject }.not_to change { ProtectedEnvironment.count }

        expect(flash[:alert]).to match(/Your environment can't be unprotected/)
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { group_maintainer }

      it 'renders 404' do
        expect { subject }.not_to change { ProtectedEnvironment.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
