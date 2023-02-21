# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettings::ScimOauthController, feature_category: :system_access do
  include AdminModeHelper

  describe 'POST admin_application_settings_scim_oauth' do
    context 'when the user is an admin' do
      let_it_be(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when admin mode is not enabled' do
        it 'returns access denied' do
          send_request

          expect(response).to redirect_to(new_admin_session_path)
        end
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        context 'when the feature is not available' do
          it 'returns not found' do
            send_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when the feature is available' do
          before do
            stub_licensed_features(instance_level_scim: true)
          end

          it 'successfully creates a token', :aggregate_failures do
            send_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['scim_api_url']).to end_with('/api/scim/v2/application')
            expect(json_response['scim_token']).to be_present
          end

          context 'when a token already exists' do
            let(:existing_token) { create(:scim_oauth_access_token, group: nil) }

            before do
              existing_token
            end

            it 'successfully resets the token', :aggregate_failures do
              send_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['scim_token']).not_to eq(existing_token.token)
              expect(ScimOauthAccessToken.where(group: nil).count).to eq(1)
            end
          end

          context 'when the SCIM token is invalid' do
            before do
              allow_next_instance_of(ScimOauthAccessToken) do |scim_token|
                allow(scim_token).to receive(:errors).and_call_original
                allow(scim_token).to receive_message_chain('errors.empty?').and_return(false)
              end
            end

            it 'returns an error' do
              send_request

              expect(response).to have_gitlab_http_status(:unprocessable_entity)
            end
          end
        end
      end
    end

    context 'when the user is not an admin' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
        stub_licensed_features(instance_level_scim: true)
      end

      it 'returns not found' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def send_request
      post "#{admin_application_settings_scim_oauth_path}.json"
    end
  end
end
