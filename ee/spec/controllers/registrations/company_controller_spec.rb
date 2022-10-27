# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::CompanyController, :saas do
  let_it_be(:user) { create(:user) }

  let(:logged_in) { true }

  before do
    sign_in(user) if logged_in
  end

  shared_examples 'user authentication' do
    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when authenticated' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  shared_examples 'a dot-com only feature' do
    context 'when not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  describe '#new' do
    subject { get :new }

    it_behaves_like 'user authentication'
    it_behaves_like 'a dot-com only feature'

    context 'on render' do
      it { is_expected.to render_template 'layouts/minimal' }
      it { is_expected.to render_template(:new) }
    end
  end

  describe '#create' do
    using RSpec::Parameterized::TableSyntax

    let(:glm_params) do
      {
        glm_source: 'some_source',
        glm_content: 'some_content'
      }
    end

    let(:params) do
      {
        company_name: 'GitLab',
        company_size: '1-99',
        phone_number: '+1 23 456-78-90',
        country: 'US',
        state: 'CA',
        website_url: 'gitlab.com'
      }.merge(glm_params)
    end

    context 'on success' do
      where(:trial_onboarding_flow, :redirect_query) do
        'true'  | { trial_onboarding_flow: true }
        'false' | {}
      end

      with_them do
        it 'creates trial or lead and redirects to the correct path' do
          expect_next_instance_of(
            GitlabSubscriptions::CreateTrialOrLeadService,
            user: user,
            params: ActionController::Parameters.new(params.merge(
                                                       trial_onboarding_flow: trial_onboarding_flow
                                                     )).permit!
          ) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.success)
          end

          post :create, params: params.merge(trial_onboarding_flow: trial_onboarding_flow)

          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(new_users_sign_up_groups_project_path(redirect_query.merge(glm_params)))
        end
      end
    end

    context 'on failure' do
      where(trial_onboarding_flow: %w[true false])

      with_them do
        it 'renders company page :new' do
          expect_next_instance_of(GitlabSubscriptions::CreateTrialOrLeadService) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
          end

          post :create, params: params.merge(trial_onboarding_flow: trial_onboarding_flow)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:new)
          expect(flash[:alert]).to eq('failed')
        end
      end
    end
  end
end
