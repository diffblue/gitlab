# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Access Tokens', :js, :saas, feature_category: :user_management do
  include Spec::Support::Helpers::ModalHelpers
  include Features::AccessTokenHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before_all do
    project.add_maintainer(user)

    create(:plan_limits, :ultimate_trial_plan, project_access_token_limit: 1)
  end

  before do
    stub_licensed_features(resource_access_token: true)
    stub_ee_application_setting(should_check_namespace_plan: true)
    sign_in(user)
  end

  shared_examples 'revoke existing token' do
    it 'can revoke existing token' do
      create_token

      visit project_settings_access_tokens_path(project)

      accept_gl_confirm(button_text: "Revoke") { click_on "Revoke" }
      expect(active_access_tokens).to have_text(_("This project has no active access tokens"))
    end
  end

  context 'when has active trial subscription' do
    let(:expected_notice) do
      s_('AccessTokens|You can only have one active project access token with a trial license. ' \
         'You cannot generate a new token until the existing token is deleted, or you upgrade your subscription.')
    end

    before do
      create(:gitlab_subscription, :ultimate_trial, namespace: group)
    end

    it 'shows access token creation form but no alert when there is no token' do
      visit project_settings_access_tokens_path(project)

      expect(page).to have_selector('#js-new-access-token-form')
      expect(page).not_to have_content(expected_notice)
    end

    it 'hides access token creation form and shows alert when there is a token' do
      create_token

      visit project_settings_access_tokens_path(project)

      expect(page).to have_content(expected_notice)
      expect(page).not_to have_selector('#js-new-access-token-form')
    end

    it_behaves_like 'revoke existing token'
  end

  context 'when has expired trial subscription' do
    before do
      create(:gitlab_subscription, :expired_trial, :free, namespace: group)
    end

    it 'hides access token creation form' do
      visit project_settings_access_tokens_path(project)

      expect(page).not_to have_selector('#js-new-access-token-form')
    end

    it_behaves_like 'revoke existing token'
  end

  def create_token
    bot_user = create(:user, :project_bot)
    project.add_maintainer(bot_user)
    create(:personal_access_token, user: bot_user)
  end
end
