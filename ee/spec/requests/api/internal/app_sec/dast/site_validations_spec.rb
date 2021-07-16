# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::AppSec::Dast::SiteValidations do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_projects: [project]) }
  let_it_be(:site_validation) { create(:dast_site_validation, dast_site_token: create(:dast_site_token, project: project)) }
  let_it_be(:job) { create(:ci_build, :running, project: project, user: developer) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe 'POST /internal/dast/site_validations/:id/transition' do
    let(:url) { "/internal/dast/site_validations/#{site_validation.id}/transition" }

    let(:event_param) { :pass }
    let(:params) { { event: event_param } }
    let(:headers) { {} }

    subject do
      post api(url), params: params, headers: headers
    end

    context 'when a job token header is not set' do
      it 'returns 401' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      context 'when user token is set' do
        it 'returns 400 and a contextual error message', :aggregate_failures do
          post api(url, developer), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to eq('message' => '400 Bad request - Must authenticate using job token')
        end
      end
    end

    context 'when a job token header is set' do
      let(:headers) { { API::Helpers::Runner::JOB_TOKEN_HEADER => job.token } }

      context 'when user does not have access to the site validation' do
        let(:job) { create(:ci_build, :running, user: create(:user)) }

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when site validation does not exist' do
        let(:site_validation) { build(:dast_site_validation, id: non_existing_record_id) }

        it 'returns 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when site validation and job are associated with different projects' do
        let_it_be(:job) { create(:ci_build, :running, user: developer) }

        it 'returns 400', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:bad_request) # Temporarily forcing job_token_scope_enabled false
        end

        context 'when the job project belongs to the same job token scope' do
          before do
            allow_next(Ci::JobToken::Scope).to receive(:includes?).with(project).and_return(true)
          end

          it 'returns 400 and a contextual error message', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq('message' => '400 Bad request - Project mismatch')
          end
        end
      end

      context 'when site validation exists' do
        context 'when the licensed feature is not available' do
          before do
            stub_licensed_features(security_on_demand_scans: false)
          end

          it 'returns 403' do
            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when the feature flag is disabled' do
          before do
            stub_feature_flags(dast_runner_site_validation: false)
          end

          it 'returns 404 and a contextual error message', :aggregate_failures do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to eq('message' => '404 Feature flag disabled: :dast_runner_site_validation')
          end
        end

        context 'when user has access to the site validation' do
          context 'when the state transition is unknown' do
            let(:event_param) { :unknown_transition }

            it 'returns 400 and a contextual error message', :aggregate_failures do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq('error' => 'event does not have a valid value')
            end
          end

          context 'when the state transition is invalid' do
            it 'returns 400 and a contextual error message', :aggregate_failures do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq('message' => '400 Bad request - Could not update DAST site validation')
            end
          end

          shared_examples 'it transitions' do |event|
            let(:event_param) { event }

            it "calls the underlying transition method: ##{event}", :aggregate_failures do
              expect(DastSiteValidation).to receive(:find).with(String(site_validation.id)).and_return(site_validation)
              expect(site_validation).to receive(event).and_call_original

              subject
            end
          end

          context 'when the state transition is valid' do
            let(:event_param) { :start }

            it 'updates the record' do
              expect { subject }.to change { site_validation.reload.state }.from('pending').to('inprogress')
            end

            it_behaves_like 'it transitions', :start
            it_behaves_like 'it transitions', :fail_op
            it_behaves_like 'it transitions', :retry
            it_behaves_like 'it transitions', :pass
          end
        end
      end
    end
  end
end
