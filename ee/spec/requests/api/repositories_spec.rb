# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Repositories, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  describe "GET /projects/:id/repository/archive(.:format)?:sha" do
    let(:route) { "/projects/#{project.id}/repository/archive" }

    subject(:request) { get api(route, user) }

    shared_examples 'an auditable and successful request' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'logs the audit event' do
        expect { request }.to change { AuditEvent.count }.by(1)
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
        let(:current_user) { user }
      end
    end

    describe 'projects download throttling' do
      before do
        project.add_developer(user)

        allow_next_instance_of(::Users::Abuse::ProjectsDownloadBanCheckService, project, user) do |service|
          allow(service).to receive(:execute).and_return(service_response)
        end

        request
      end

      context 'when user is banned from the project\'s top-level group' do
        let(:service_response) { ServiceResponse.error(message: 'User has been banned') }

        it 'returns forbidden error' do
          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.body).to match 'You are not allowed to download code from this project.'
        end
      end

      context 'when user is not banned from the project\'s top-level group' do
        let(:service_response) { ServiceResponse.success }

        it 'returns the repository archive' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
