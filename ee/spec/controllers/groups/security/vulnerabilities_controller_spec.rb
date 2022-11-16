# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::VulnerabilitiesController, feature_category: :vulnerability_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    subject { get :index, params: { group_id: group.to_param } }

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'and user is allowed to access group security vulnerabilities' do
        before do
          group.add_developer(user)
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      context 'when user is not allowed to access group security vulnerabilities' do
        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:unavailable) }
      end
    end

    context 'when security dashboard feature is disabled' do
      it { is_expected.to have_gitlab_http_status(:ok) }
      it { is_expected.to render_template(:unavailable) }
    end
  end
end
