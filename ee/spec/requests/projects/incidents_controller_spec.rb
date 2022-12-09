# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IncidentsController, feature_category: :incident_management do
  let_it_be(:issue) { create(:incident) }
  let_it_be(:project) { issue.project }
  let_it_be(:user) { issue.author }

  before do
    login_as(user)
  end

  describe 'GET #show' do
    it 'exposes the escalation_policies licensed feature setting' do
      stub_licensed_features(escalation_policies: true)

      get project_issue_path(project, issue)

      expect(response.body).to have_pushed_frontend_feature_flags(escalationPolicies: true)
    end
  end
end
