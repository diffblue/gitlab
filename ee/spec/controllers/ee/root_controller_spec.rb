# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RootController, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  describe 'GET #index' do
    context 'when user is not logged in' do
      context 'on a Geo primary node' do
        let_it_be(:primary_node) { create(:geo_node, :primary) }

        before do
          stub_current_geo_node(primary_node)
        end

        it 'redirects to the sign-in page' do
          get :index

          expect(response).to redirect_to(new_user_session_path)
        end

        context 'when a custom home page URL is defined' do
          before do
            stub_application_setting(home_page_url: 'https://custom.gitlab.com/foo')
          end

          it 'redirects the user to the custom home page URL' do
            get :index

            expect(response).to redirect_to('https://custom.gitlab.com/foo')
          end
        end
      end

      context 'on a Geo secondary node' do
        let_it_be(:secondary_node) { create(:geo_node) }

        before do
          stub_current_geo_node(secondary_node)
        end

        it 'redirects to the sign-in page' do
          get :index

          expect(response).to redirect_to(new_user_session_path)
        end

        context 'when a custom home page URL is defined' do
          before do
            stub_application_setting(home_page_url: 'https://custom.gitlab.com/foo')
          end

          it 'redirects to the sign-in page' do
            get :index

            expect(response).to redirect_to(new_user_session_path)
          end
        end
      end
    end

    context 'with a user' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        allow(subject).to receive(:current_user).and_return(user)
      end

      context 'who has customized their dashboard setting for operations' do
        before do
          user.dashboard = 'operations'
        end

        context 'when licensed' do
          before do
            stub_licensed_features(operations_dashboard: true)
          end

          it 'redirects to operations dashboard' do
            get :index

            expect(response).to redirect_to operations_path
          end
        end

        context 'when unlicensed' do
          before do
            stub_licensed_features(operations_dashboard: false)
          end

          it 'renders the default dashboard' do
            get :index

            expect(response).to render_template 'dashboard/projects/index'
          end
        end
      end
    end
  end
end
