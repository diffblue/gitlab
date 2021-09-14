# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::ProjectsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project) }

  describe 'GET #new' do
    subject { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      let(:dev_env_or_com) { true }

      before do
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
      end

      context 'when on .com' do
        it { is_expected.to have_gitlab_http_status(:not_found) }

        context 'with a namespace in the URL' do
          subject { get :new, params: { namespace_id: namespace.id } }

          it { is_expected.to have_gitlab_http_status(:not_found) }

          context 'with sufficient access' do
            before do
              namespace.add_owner(user)
            end

            it { is_expected.to have_gitlab_http_status(:ok) }
            it { is_expected.to render_template(:new) }
          end
        end
      end

      context 'when not on .com' do
        let(:dev_env_or_com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    it_behaves_like "Registrations::ProjectsController POST #create"

    context 'force_company_trial_experiment' do
      let(:project) { create(:project, namespace: namespace) }

      let(:params) { { namespace_id: namespace.id, name: 'New project', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

      before do
        namespace.add_owner(user)
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(true)
        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:execute).and_return(project)
        end
      end

      it 'tracks an event for the force_company_trial experiment', :experiment do
        expect(experiment(:force_company_trial)).to track(:create_project, namespace: namespace, project: an_instance_of(Project), user: user)
          .with_context(user: user)
          .on_next_instance

        post :create, params: { project: params }
      end
    end
  end
end
