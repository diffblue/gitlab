# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::VerificationController, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  describe 'GET #new' do
    let(:params) { {} }

    subject(:get_new) { get :new, params: params }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when on .com', :saas do
        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template 'layouts/minimal' }
        it { is_expected.to render_template(:new) }

        it 'publishes the experiment' do
          expect_next_instance_of(ApplicationExperiment) do |instance|
            expect(instance).to receive(:publish)
          end

          get_new
        end

        context 'with project_id in params' do
          let_it_be(:project) { create(:project) }
          let(:params) { { project_id: project.id } }

          it 'assigns to learn_gitlab onboarding' do
            get_new

            expect(assigns(:next_step_url)).to eq(onboarding_project_learn_gitlab_path(project))
          end

          context 'when project_id is blank' do
            let(:params) { { project_id: nil } }

            it 'assigns to root_path' do
              get_new

              expect(assigns(:next_step_url)).to eq(root_path)
            end
          end
        end

        context 'without project_id in params' do
          it 'assigns to root_path' do
            get_new

            expect(assigns(:next_step_url)).to eq(root_path)
          end
        end
      end

      context 'when not on .com' do
        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
