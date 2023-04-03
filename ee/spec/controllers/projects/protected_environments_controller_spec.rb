# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::ProtectedEnvironmentsController, feature_category: :continuous_delivery do
  let(:project) { create(:project) }
  let(:current_user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  before do
    sign_in(current_user)
  end

  describe '#POST create' do
    let(:params) do
      attributes_for(
        :protected_environment,
        deploy_access_levels_attributes: [{ access_level: maintainer_access }],
        required_approval_count: 1
      )
    end

    subject do
      post :create,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          protected_environment: params
        }
    end

    context 'with valid access and params' do
      before do
        project.add_maintainer(current_user)
      end

      context 'with valid params' do
        it 'creates a new ProtectedEnvironment' do
          expect do
            subject
          end.to change { ProtectedEnvironment.count }.by(1)
        end

        it 'sets a flash' do
          subject

          expect(controller).to set_flash[:notice].to(/environment has been protected/)
        end

        it 'redirects to CI/CD settings' do
          subject

          expect(response).to redirect_to project_settings_ci_cd_path(project, anchor: 'js-protected-environments-settings')
        end
      end

      context 'with invalid params' do
        let(:params) do
          attributes_for(
            :protected_environment,
            name: '',
            deploy_access_levels_attributes: [{ access_level: maintainer_access }]
          )
        end

        it 'does not create a new ProtectedEnvironment' do
          expect do
            subject
          end.not_to change { ProtectedEnvironment.count }
        end

        it 'redirects to CI/CD settings' do
          subject

          expect(response).to redirect_to project_settings_ci_cd_path(project, anchor: 'js-protected-environments-settings')
        end
      end
    end

    context 'with invalid access' do
      before do
        project.add_developer(current_user)
      end

      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#PUT update' do
    let(:protected_environment) { create(:protected_environment, project: project) }
    let(:deploy_access_level) { protected_environment.deploy_access_levels.first }
    let(:deploy_access_level_to_destroy) do
      create(:protected_environment_deploy_access_level, protected_environment: protected_environment)
    end

    let(:access_levels_params) do
      {
        deploy_access_levels_attributes: [
          { id: deploy_access_level.id, access_level: Gitlab::Access::DEVELOPER, user_id: nil },
          { id: deploy_access_level_to_destroy.id, _destroy: true },
          { access_level: maintainer_access }
        ],
        required_approval_count: 3
      }
    end

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: protected_environment.id,
        protected_environment: access_levels_params
      }
    end

    subject do
      put :update, params: params, as: :json
    end

    context 'when the user is authorized' do
      before do
        project.add_maintainer(current_user)

        subject
      end

      it 'finds the requested protected environment' do
        expect(assigns(:protected_environment)).to eq(protected_environment)
      end

      it 'updates the protected environment', :aggregate_failures do
        protected_environment.reload
        deploy_access_level.reload

        expect(deploy_access_level.access_level).to eq(Gitlab::Access::DEVELOPER)
        expect(deploy_access_level.user_id).to be_nil
        expect(protected_environment.deploy_access_levels.count).to eq(2)
        expect(protected_environment.required_approval_count).to eq(3)
        expect(ProtectedEnvironments::DeployAccessLevel.find_by_id(deploy_access_level_to_destroy.id)).to be_nil
      end

      it 'is successful' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the user is not authorized' do
      before do
        project.add_developer(current_user)

        subject
      end

      it 'is not successful' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#DELETE destroy' do
    let!(:protected_environment) { create(:protected_environment, project: project) }

    subject do
      delete :destroy,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: protected_environment.id
        }
    end

    context 'when the user is authorized' do
      before do
        project.add_maintainer(current_user)
      end

      it 'finds the requested protected environment' do
        subject

        expect(assigns(:protected_environment)).to eq(protected_environment)
      end

      it 'deletes the requested protected environment' do
        expect do
          subject
        end.to change { ProtectedEnvironment.count }.from(1).to(0)
      end

      it 'redirects to CI/CD settings' do
        subject

        expect(response).to redirect_to project_settings_ci_cd_path(project, anchor: 'js-protected-environments-settings')
      end
    end

    context 'when the user is not authorized' do
      before do
        project.add_developer(current_user)
      end

      it 'is not successful' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
