# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::UpcomingReconciliations, :api, feature_category: :purchase do
  describe 'PUT /internal/upcoming_reconciliations' do
    before do
      stub_application_setting(check_namespace_plan: true)
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        put api('/internal/upcoming_reconciliations')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as user' do
      let_it_be(:user) { create(:user) }

      it 'returns authentication error' do
        put api('/internal/upcoming_reconciliations', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let_it_be(:admin) { create(:admin) }
      let_it_be(:namespace) { create(:namespace) }

      let(:namespace_id) { namespace.id }
      let(:upcoming_reconciliations) do
        [{
           namespace_id: namespace_id,
           next_reconciliation_date: Date.today + 5.days,
           display_alert_from: Date.today - 2.days
         }]
      end

      subject(:put_upcoming_reconciliations) do
        put api('/internal/upcoming_reconciliations', admin), params: { upcoming_reconciliations: upcoming_reconciliations }
      end

      it 'returns success' do
        put_upcoming_reconciliations

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when namespace_id is empty' do
        let(:namespace_id) { nil }

        it 'returns error', :aggregate_failures do
          put_upcoming_reconciliations

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response.dig('error')).to eq('upcoming_reconciliations[namespace_id] is empty')
        end
      end

      context 'when update service failed' do
        let(:error_message) { 'update_service_error' }

        before do
          allow_next_instance_of(::UpcomingReconciliations::UpdateService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
          end
        end

        it 'returns error', :aggregate_failures do
          put_upcoming_reconciliations

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response.dig('message', 'error')).to eq(error_message)
        end
      end
    end

    context 'when not gitlab.com', :aggregate_failures do
      it 'returns 403 error' do
        stub_application_setting(check_namespace_plan: false)

        put api('/internal/upcoming_reconciliations')

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response.dig('message')).to eq('403 Forbidden - This API is gitlab.com only!')
      end
    end
  end

  describe 'DELETE /internal/upcoming_reconciliations' do
    let_it_be(:namespace) { create(:namespace) }

    before do
      stub_application_setting(check_namespace_plan: true)
    end

    context 'when the request is not authenticated' do
      it 'returns authentication error' do
        delete api("/internal/upcoming_reconciliations?namespace_id=#{namespace.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as user' do
      it 'returns authentication error', :aggregate_failures do
        user = create(:user)

        expect { delete api("/internal/upcoming_reconciliations?namespace_id=#{namespace.id}", user) }
          .not_to change(GitlabSubscriptions::UpcomingReconciliation, :count)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as an admin' do
      let_it_be(:admin) { create(:admin) }

      context 'when the request is not for .com' do
        before do
          stub_application_setting(check_namespace_plan: false)
        end

        it 'returns an error', :aggregate_failures do
          expect { delete api("/internal/upcoming_reconciliations?namespace_id=#{namespace.id}", admin) }
            .not_to change(GitlabSubscriptions::UpcomingReconciliation, :count)

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.body).to include('403 Forbidden - This API is gitlab.com only!')
        end
      end

      context 'when the namespace_id is missing' do
        it 'returns a 400 error', :aggregate_failures do
          expect { delete api("/internal/upcoming_reconciliations", admin) }
            .not_to change(GitlabSubscriptions::UpcomingReconciliation, :count)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include 'namespace_id is missing'
        end
      end

      context 'when there is an upcoming reconciliation for the namespace' do
        it 'destroys the reconciliation and returns success', :aggregate_failures do
          create(:upcoming_reconciliation, namespace_id: namespace.id)

          expect { delete api("/internal/upcoming_reconciliations?namespace_id=#{namespace.id}", admin) }
            .to change { GitlabSubscriptions::UpcomingReconciliation.where(namespace_id: namespace.id).count }
            .by(-1)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when the namespace_id does not have an upcoming reconciliation' do
        it 'returns a not found error' do
          expect { delete api("/internal/upcoming_reconciliations?namespace_id=#{namespace.id}", admin) }
            .not_to change(GitlabSubscriptions::UpcomingReconciliation, :count)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
