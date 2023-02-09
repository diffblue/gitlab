# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registration Onboarding', type: :request,
  feature_category: :authentication_and_authorization do
  describe '#continuous_onboarding_getting_started' do
    it 'redirects to learn gitlab onboarding' do
      project = create(:project, namespace: create(:group))
      path = "/#{project.namespace.name}/#{project.name}/-/users/sign_up/welcome/continuous_onboarding_getting_started"

      expect(get(path)).to redirect_to(onboarding_project_learn_gitlab_path(project))
    end
  end
end
