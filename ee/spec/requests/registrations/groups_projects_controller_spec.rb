# frozen_string_literal: true

require 'spec_helper'

# TODO: remove after the deployment
# https://gitlab.com/gitlab-org/gitlab/-/issues/411208
RSpec.describe Registrations::GroupsProjectsController, feature_category: :onboarding do
  let_it_be(:user) { create(:user, onboarding_in_progress: true) }

  let_it_be(:user_detail) do
    create(:user_detail, user: user, onboarding_step_url: '/users/sign_up/groups_projects/new')
  end

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    sign_in(user)
  end

  context 'when create request from old page' do
    let(:params) do
      {
        trial_onboarding_flow: false,
        glm_source: '_glm_source_',
        glm_content: '_glm_content_',
        trial: false
      }
    end

    it 'redirects to the new page with url params' do
      post users_sign_up_groups_projects_path(params)

      expect(response).to redirect_to new_users_sign_up_group_path(params)
    end
  end

  context 'when import request from old page' do
    it 'redirects to the new page' do
      post import_users_sign_up_groups_projects_path

      expect(response).to redirect_to new_users_sign_up_group_path
    end
  end
end
