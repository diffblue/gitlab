# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::ReportingController, type: :request do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:feature_flag_enabled) { true }
  let(:licensed_feature_available) { true }

  before do
    stub_feature_flags(limit_unique_project_downloads_per_namespace_user: feature_flag_enabled)
    stub_licensed_features(unique_project_download_limit: licensed_feature_available)

    sign_in(user)
  end

  shared_examples 'renders 404' do
    it 'renders 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples '404 when feature is unavailable' do
    before do
      subject
    end

    context 'when feature flag is disabled' do
      let(:feature_flag_enabled) { false }

      it_behaves_like 'renders 404'
    end

    context 'when feature flag is disabled' do
      let(:licensed_feature_available) { false }

      it_behaves_like 'renders 404'
    end

    context 'when subgroup' do
      let(:group) { create(:group, parent: create(:group)) }

      it_behaves_like 'renders 404'
    end
  end

  describe 'GET /groups/:group_id/-/settings/reporting' do
    subject(:request) { get group_settings_reporting_path(group) }

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      it_behaves_like '404 when feature is unavailable'
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
    let(:params) { { group: { unique_project_download_limit: 10 } } }

    subject(:request) do
      patch(group_settings_reporting_path(group), params: params)
    end

    context 'when user is not an owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is an owner' do
      before do
        group.add_owner(user)
      end

      it_behaves_like '404 when feature is unavailable'

      it 'redirects back to show page' do
        request

        expect(response).to redirect_to(group_settings_reporting_path(group))
        expect(flash[:notice]).to include("Group '#{group.name}' was successfully updated.")
      end

      context 'update failed' do
        let(:params) { { group: { unique_project_download_limit: -1 } } }

        it 're-renders show template' do
          request

          expect(response).not_to have_gitlab_http_status(:redirect)
          expect(response).to render_template(:show)
        end
      end
    end
  end
end
