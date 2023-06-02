# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users (JavaScript fixtures)', feature_category: :user_profile do
  include JavaScriptFixturesHelpers
  include ApiHelpers

  let_it_be(:user) { create(:user) }

  describe UsersController, '(JavaScript fixtures)', type: :controller do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project_empty_repo, group: group) }

    include_context '[EE] with user contribution events'

    before do
      stub_licensed_features(epics: true)
      group.add_owner(user)
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'controller/users/activity.json' do
      get :activity, params: { username: user.username, limit: 50 }, format: :json

      expect(response).to be_successful
    end
  end
end
