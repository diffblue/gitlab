# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PreferencesController, feature_category: :user_profile do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'PATCH update' do
    def go(params: {}, format: :json)
      params.reverse_merge!(
        color_scheme_id: '1',
        dashboard: 'stars',
        theme_id: '1'
      )

      patch :update, params: { user: params }, format: format
    end

    context 'when updating security dashboard feature' do
      subject { patch :update, params: { user: { group_view: group_view } }, format: :json }

      let(:group_view) { 'security_dashboard' }

      context 'when the security dashboard feature is enabled' do
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

      context 'when the security dashboard feature is disabled' do
        context 'when security dashboard feature enabled' do
          specify do
            expect { subject }.not_to change { user.reload.group_view_security_dashboard? }
          end
        end
      end
    end

    context 'when updating code suggestions setting', :saas do
      let(:user_on_com) { create(:user) }

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        sign_in(user_on_com)
      end

      it 'updates the attribute' do
        patch :update, params: { user: { code_suggestions: true, format: :json } }

        expect(user_on_com.reload.code_suggestions).to eq(true)
      end

      context 'when the feature flags are disabled' do
        before do
          stub_feature_flags(ai_assist_ui: false, ai_assist_flag: false)
        end

        it 'does not update attributes' do
          expect do
            patch :update, params: { user: { code_suggestions: true, format: :json } }
          end.not_to change {
            user_on_com.reload.code_suggestions
          }
        end
      end
    end

    context 'on zoekt indexed namespaces', feature_category: :global_search do
      context 'when user is not a member of any zoekt indexed namespaces' do
        before do
          allow(::Zoekt::IndexedNamespace).to receive(:where).and_return([])
        end

        it 'does not update enabled_zoekt preference of user' do
          prefs = { enabled_zoekt: false }

          go params: prefs
          user.reload

          expect(user.enabled_zoekt).to eq(true)
        end
      end

      context 'when user is a member of a zoekt indexed namespace' do
        before do
          allow(::Zoekt::IndexedNamespace).to receive(:where).and_return([::Zoekt::IndexedNamespace.new])
        end

        it 'updates enabled_zoekt preference of user' do
          prefs = { enabled_zoekt: false }

          go params: prefs
          user.reload

          expect(user.enabled_zoekt).to eq(false)
        end
      end
    end
  end
end
