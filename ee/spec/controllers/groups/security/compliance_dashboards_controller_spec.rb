# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::ComplianceDashboardsController, feature_category: :compliance_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    subject { get :show, params: { group_id: group.to_param } }

    context 'when compliance dashboard feature is enabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: true)
      end

      context 'and user is allowed to access group compliance dashboard' do
        before_all do
          group.add_owner(user)
        end

        it { is_expected.to have_gitlab_http_status(:success) }

        it_behaves_like 'tracking unique visits', :show do
          let(:request_params) { { group_id: group.to_param } }
          let(:target_id) { 'g_compliance_dashboard' }
        end

        it_behaves_like 'internal event tracking' do
          let(:namespace) { group }
          let(:event) { 'g_compliance_dashboard' }
        end
      end

      context 'when user is not allowed to access group compliance dashboard' do
        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end

    context 'when compliance dashboard feature is disabled' do
      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
