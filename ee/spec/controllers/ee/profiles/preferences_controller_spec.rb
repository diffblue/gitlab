# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PreferencesController, feature_category: :user_profile do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'PATCH update' do
    subject { patch :update, params: { user: { group_view: group_view } }, format: :json }

    let(:group_view) { 'security_dashboard' }

    context 'when security dashboard feature enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'and valid group view choice is submitted' do
        it "changes the user's preferences" do
          expect { subject }.to change { user.reload.group_view_security_dashboard? }.from(false).to(true)
        end

        context 'and an invalid group view choice is submitted' do
          let(:group_view) { 'foo' }

          it 'responds with an error message' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.parsed_body['message']).to match(/Failed to save preferences/)
            expect(response.parsed_body['type']).to eq('alert')
          end
        end
      end
    end

    context 'when security dashboard feature is disabled' do
      context 'when security dashboard feature enabled' do
        specify do
          expect { subject }.not_to change { user.reload.group_view_security_dashboard? }
        end
      end
    end
  end
end
