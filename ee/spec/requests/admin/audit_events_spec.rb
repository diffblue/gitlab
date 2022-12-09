# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view audit events', feature_category: :audit_events do
  include AdminModeHelper

  describe 'GET /audit_events' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:audit_event) { create(:user_audit_event) }

    before do
      stub_licensed_features(admin_audit_log: true)

      login_as(admin)
    end

    context 'when admin mode is enabled' do
      before do
        enable_admin_mode!(admin)
      end

      it 'returns 200 response' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'avoids N+1 DB queries', :request_store do
        # warm up cache so these initial queries would not leak in our QueryRecorder
        send_request

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { send_request }

        create_list(:user_audit_event, 2)

        expect do
          send_request
        end.not_to exceed_all_query_limit(control)
      end
    end

    context 'when admin mode is disabled' do
      it 'redirects to admin mode enable' do
        send_request

        expect(response).to redirect_to(new_admin_session_path)
      end
    end

    def send_request
      get admin_audit_logs_path
    end
  end
end
