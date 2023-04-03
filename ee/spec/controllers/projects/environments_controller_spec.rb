# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::EnvironmentsController, feature_category: :continuous_delivery do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:environment) do
    create(:environment, name: 'production', project: project)
  end

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET #show' do
    context 'deployment approvals' do
      before do
        create(:deployment, :success, environment: environment, project: project) do |deployment|
          create(:deployment_approval, deployment: deployment)
        end
        create(:deployment, :failed, environment: environment, project: project)
      end

      it 'preloads approvals their authors' do
        get :show, params: environment_params

        assigns(:deployments).each do |deployment|
          expect(deployment.association(:approvals)).to be_loaded

          deployment.approvals.each do |approval|
            expect(approval.association(:user)).to be_loaded
          end
        end
      end
    end
  end

  describe '#GET terminal' do
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    before do
      allow(License).to receive(:feature_available?).and_call_original
      allow(License).to receive(:feature_available?).with(:protected_environments).and_return(true)
    end

    context 'when environment is protected' do
      context 'when user does not have access to it' do
        before do
          protected_environment

          get :terminal, params: environment_params
        end

        it 'responds with access denied' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user has access to it' do
        before do
          protected_environment.deploy_access_levels.create!(user: user)

          get :terminal, params: environment_params
        end

        it 'is successful' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when environment is not protected' do
      it 'is successful' do
        get :terminal, params: environment_params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'POST #cancel_auto_stop' do
    subject { post :cancel_auto_stop, params: params }

    let(:params) { environment_params }

    context 'when environment is set as auto-stop' do
      let(:environment) { create(:environment, :will_auto_stop, name: 'staging', project: project) }

      it_behaves_like 'successful response for #cancel_auto_stop'

      context 'when the environment is protected' do
        before do
          stub_licensed_features(protected_environments: true)
          create(:protected_environment, name: 'staging', project: project)
        end

        it 'shows not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project, id: environment.id)
  end
end
