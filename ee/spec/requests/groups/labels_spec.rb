# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view audit events', feature_category: :team_planning do
  describe 'GET /groups/:group/-/audit_events' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:group1) { create(:group, parent: group) }

    it 'returns 200 response' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'avoids N+1 DB queries', :request_store do
      create_list(:group, 3, parent: group)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_request }

      expect { send_request }.not_to exceed_all_query_limit(control)
    end

    def send_request
      get group_labels_path(group, include_descendant_groups: true, format: :json)
    end
  end
end
