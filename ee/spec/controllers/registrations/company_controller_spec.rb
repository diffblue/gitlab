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
    context 'on success' do
      let(:params) do
        {
          company_name: 'GitLab',
          company_size: '1-99',
          phone_number: '+1 23 456-78-90',
          country: 'US',
          state: 'CA',
          website_url: 'gitlab.com',
          work_email: user.email,
          uid: user.id,
          provider: 'gitlab',
          setup_for_company: user.setup_for_company,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          newsletter_segment: user.email_opted_in
        }
      end

      let(:hand_raise_params) { ActionController::Parameters.new(params).permit! }
      let(:lead_params) { { trial_user: hand_raise_params } }

      let(:trial_onboarding_flow) { new_users_sign_up_groups_project_path(trial_onboarding_flow: true) }
      let(:skip_trial) { new_users_sign_up_groups_project_path(skip_trial: true) }

      where(:trial, :expected_params, :post_service, :redirect_query) do
        true  | ref(:lead_params)       | GitlabSubscriptions::CreateLeadService          | ref(:trial_onboarding_flow)
        false | ref(:hand_raise_params) | GitlabSubscriptions::CreateHandRaiseLeadService | ref(:skip_trial)
      end

      with_them do
        it 'calls the correct service' do
          expect_next_instance_of(post_service) do |service|
            expect(service).to receive(:execute).with(expected_params).and_return({ success: true })
          end

          post_params = params.merge(trial: trial)

          post :create, params: post_params
          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(redirect_query)
        end
      end
    end

    context 'on failure' do
      where(:trial, :post_service) do
        true  | GitlabSubscriptions::CreateLeadService
        false | GitlabSubscriptions::CreateHandRaiseLeadService
      end

      with_them do
        it 'calls the correct service' do
          expect_next_instance_of(post_service) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
          end

          post :create, params: { trial: trial }
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:new)
        end
      end
    end
  end
end
