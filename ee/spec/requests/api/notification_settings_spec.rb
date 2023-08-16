# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NotificationSettings, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, creator_id: user.id, namespace: group) }

  describe 'GET /projects/:id/notification_settings' do
    it 'does not include group-level custom notification events' do
      create(:notification_setting, source: project, user: user, level: :custom)

      get api("/projects/#{project.id}/notification_settings", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['events']).not_to have_key('new_epic')
    end
  end

  describe 'GET /groups/:id/notification_settings' do
    it 'includes group-level custom notification events' do
      create(:notification_setting, source: group, user: user, level: :custom)

      get api("/groups/#{group.id}/notification_settings", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['events']).to have_key('new_epic')
    end
  end
end
