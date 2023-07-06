# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettings::RolesAndPermissionsController, :enable_admin_mode, feature_category: :user_management do
  describe 'GET #index' do
    subject(:get_index) { get admin_application_settings_roles_and_permissions_path }

    shared_examples 'not found' do
      it 'is not found' do
        get_index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with non-admin user' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it_behaves_like 'not found'
    end

    context 'when no user is logged in' do
      it 'redirects to login page' do
        get_index

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end

    context 'with an admin user' do
      let_it_be(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when `custom_roles_ui_self_managed` feature flag is disabled' do
        before do
          stub_feature_flags(custom_roles_ui_self_managed: false)
        end

        it_behaves_like 'not found'
      end

      context 'when `custom_roles_ui_self_managed` feature flag is enabled' do
        context 'when `custom_roles` license is disabled' do
          it_behaves_like 'not found'
        end

        context 'when `custom_roles` license is enabled' do
          before do
            stub_licensed_features(custom_roles: true)
          end

          it 'returns a 200 status code' do
            get_index

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end
end
