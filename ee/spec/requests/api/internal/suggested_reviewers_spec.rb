# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::SuggestedReviewers, feature_category: :workflow_automation do
  describe 'POST /internal/suggested_reviewers/tokens' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:secret) do
      SecureRandom.random_bytes(Gitlab::AppliedMl::SuggestedReviewers::SECRET_LENGTH)
    end

    let(:url) { '/internal/suggested_reviewers/tokens' }
    let(:params) { { project_id: project.id } }
    let(:headers) { {} }

    subject do
      post api(url), params: params, headers: headers
    end

    before do
      allow(Gitlab::AppliedMl::SuggestedReviewers).to receive(:secret).and_return(secret)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(suggested_reviewers_internal_api: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(suggested_reviewers_internal_api: true)
      end

      context 'when authentication header is not set', :aggregate_failures do
        it 'returns 401' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response).to eq('message' => 'Suggested Reviewers JWT authentication invalid')
        end
      end

      context 'when authentication header is set' do
        let(:headers) do
          jwt_token = JWT.encode(
            { 'iss' => Gitlab::AppliedMl::SuggestedReviewers::JWT_ISSUER, 'iat' => 1.minute.ago.to_i },
            secret, 'HS256'
          )

          { Gitlab::AppliedMl::SuggestedReviewers::INTERNAL_API_REQUEST_HEADER => jwt_token }
        end

        context 'when project is not allowed to suggest reviewers' do
          before do
            stub_licensed_features(suggested_reviewers: false)
          end

          it 'returns 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when project is allowed to suggest reviewers', :saas do
          before do
            stub_feature_flags(suggested_reviewers_control: true)
            stub_licensed_features(suggested_reviewers: true)
            project.project_setting.update!(suggested_reviewers_enabled: true)
          end

          context 'when create token service fails' do
            let(:service) { instance_spy(ResourceAccessTokens::CreateService) }
            let(:error_response) do
              ServiceResponse.error(message: 'something went wrong')
            end

            before do
              allow(service).to receive(:execute).and_return(error_response)
              allow(ResourceAccessTokens::CreateService).to receive(:new).and_return(service)
            end

            it 'returns 400', :aggregate_failures do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq('message' => '400 Bad request - something went wrong')
            end
          end

          context 'when create token service succeeds' do
            it 'returns 200', [:freeze_time, :aggregate_failures] do
              expires_at = 1.day.from_now.to_date.to_s

              subject

              expect(response).to have_gitlab_http_status(:created)
              expect(json_response).to include(
                'name' => 'Suggested reviewers token',
                'access_level' => Gitlab::Access::REPORTER,
                'scopes' => ['read_api'],
                'expires_at' => expires_at,
                'token' => kind_of(String)
              )
            end
          end
        end
      end
    end
  end
end
