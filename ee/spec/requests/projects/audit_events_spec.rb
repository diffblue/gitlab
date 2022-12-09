# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view audit events', feature_category: :audit_events do
  describe 'GET /:namespace/:project/-/audit_events' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }
    let_it_be(:audit_event) { create(:project_audit_event, entity_id: project.id) }

    before do
      stub_licensed_features(audit_events: true)

      login_as(user)
    end

    it 'returns 200 response' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'avoids N+1 DB queries', :request_store do
      send_request

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_request }

      create_list(:project_audit_event, 2, entity_id: project.id)

      expect do
        send_request
      end.not_to exceed_all_query_limit(control)
    end

    def send_request
      get namespace_project_audit_events_path(
        namespace_id: project.namespace,
        project_id: project
      )
    end
  end
end
