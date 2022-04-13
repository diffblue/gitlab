# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::CompanyController do
  let_it_be(:user) { create(:user, email_opted_in: true, last_name: 'Doe') }

  let(:logged_in) { true }

  before do
    sign_in(user) if logged_in
    allow(::Gitlab).to receive(:com?).and_return(true)
  end

  shared_examples 'an authenticated endpoint' do
    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to redirect_to(new_trial_registration_url) }
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

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'on render' do
      it { is_expected.to render_template 'layouts/minimal' }
      it { is_expected.to render_template(:new) }
    end
  end
  describe '#create' do
    using RSpec::Parameterized::TableSyntax

    let(:params) do
      {
        company_name: 'GitLab',
        company_size: '1-99',
        phone_number: '+1 23 456-78-90',
        country: 'US',
        state: 'CA',
        website_url: 'gitlab.com'
      }
    end

    context 'on success' do
      where(:trial, :redirect_query) do
        'true'  | { trial_onboarding_flow: true }
        'false' | { skip_trial: true }
      end

      with_them do
        it 'creates trial or lead and redirects to the corect path' do
          expect_next_instance_of(GitlabSubscriptions::CreateTrialOrLeadService) do |service|
            expect(service).to receive(:execute).with({
              user: user,
              params: ActionController::Parameters.new(params.merge({ trial: trial })).permit!
            }).and_return({ success: true })
          end

          post :create, params: params.merge({ trial: trial })
          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(new_users_sign_up_groups_project_path(redirect_query))
        end
      end
    end

    context 'on failure' do
      where(trial: %w[true false])

      with_them do
        it 'renders company page :new' do
          expect_next_instance_of(GitlabSubscriptions::CreateTrialOrLeadService) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
          end

          post :create, params: params.merge({ trial: trial })
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:new)
        end
      end
    end
  end
end
