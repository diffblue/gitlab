# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ApplicationController, type: :request, feature_category: :shared do
  context 'with redirection due to onboarding', feature_category: :onboarding do
    let(:onboarding_in_progress) { true }
    let(:url) { '_onboarding_step_' }
    let(:should_check_namespace_plan) { true }

    let(:user) do
      create(:user, onboarding_in_progress: onboarding_in_progress).tap do |record|
        create(:user_detail, user: record, onboarding_step_url: url)
      end
    end

    before do
      stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
      sign_in(user)
    end

    context 'when on SaaS' do
      it 'redirects to the onboarding step' do
        get root_path

        expect(response).to redirect_to(url)
      end

      context 'when onboarding is disabled' do
        let(:onboarding_in_progress) { false }

        it 'does not redirect to the onboarding step' do
          get root_path

          expect(response).not_to be_redirect
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(ensure_onboarding: false)
        end

        it 'does not redirect to the onboarding step' do
          get root_path

          expect(response).not_to be_redirect
        end
      end

      context 'when request path equals redirect path' do
        let(:url) { root_path }

        it 'does not redirect to the onboarding step' do
          get root_path

          expect(response).not_to be_redirect
        end
      end

      context 'when post request' do
        it 'does not redirect to the onboarding step' do
          post users_sign_up_company_path

          expect(response).not_to be_redirect
        end
      end
    end

    context 'when on not on SaaS' do
      let(:should_check_namespace_plan) { false }

      it 'redirects to the onboarding step' do
        get root_path

        expect(response).not_to be_redirect
      end
    end
  end
end
