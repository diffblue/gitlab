# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Repositories do
  let(:project) { create(:project, :repository) }

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    shared_examples 'an auditable and successful request' do
      let(:route) { "/projects/#{project.id}/repository/archive" }

      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'logs the audit event' do
        expect do
          get api(route, current_user)
        end.to change { AuditEvent.count }.by(1)
      end

      it 'sends the archive' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when unauthenticated', 'and project is public' do
      it_behaves_like 'an auditable and successful request' do
        let_it_be(:project) { create(:project, :public, :repository) }
        let(:current_user) { nil }
      end
    end

    context 'when authenticated', 'as a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'an auditable and successful request' do
        let(:user) { create(:user) }
        let(:current_user) { user }
      end
    end
  end
end
