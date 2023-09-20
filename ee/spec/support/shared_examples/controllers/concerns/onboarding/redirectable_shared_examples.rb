# frozen_string_literal: true

RSpec.shared_examples EE::Onboarding::Redirectable do
  context 'when onboarding is enabled', :saas do
    let(:params) { glm_params.merge(bogus: '_bogus_') }

    before do
      stub_application_setting(check_namespace_plan: true)
    end

    it 'onboards the user' do
      post_create

      expect(response).to redirect_to(users_sign_up_welcome_path(glm_params))
      created_user = User.find_by_email(new_user_email)
      expect(created_user).to be_onboarding_in_progress
      expect(created_user.user_detail.onboarding_step_url).to eq(users_sign_up_welcome_path(glm_params))
    end
  end

  context 'when onboarding is disabled' do
    before do
      stub_application_setting(check_namespace_plan: false)
    end

    it 'does not onboard the user' do
      post_create

      expect(response).to redirect_to(dashboard_projects_path)
      created_user = User.find_by_email(new_user_email)
      expect(created_user).not_to be_onboarding_in_progress
      expect(created_user.user_detail.onboarding_step_url).to be_nil
    end
  end
end
