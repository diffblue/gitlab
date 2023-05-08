# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CiCdAnalyticsController, feature_category: :team_planning do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:current_user) { reporter }

  before_all do
    group.add_guest(guest)
    group.add_reporter(reporter)
  end

  before do
    stub_licensed_features(group_ci_cd_analytics: true)

    sign_in(current_user) if current_user
  end

  def make_request
    get :show, params: { group_id: group.to_param }
  end

  shared_examples 'returns a 403' do
    it do
      make_request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET #show' do
    it 'renders the #show page' do
      make_request

      expect(response).to render_template :show
    end

    context "when the current user doesn't have access" do
      context 'when the user is a guest' do
        let(:current_user) { guest }

        it_behaves_like 'returns a 403'
      end

      context "when the user doesn't belong to the group" do
        let(:current_user) { non_member }

        it_behaves_like 'returns a 403'
      end

      context "when the user is not signed in" do
        let(:current_user) { nil }

        it 'redirects the user to the login page' do
          make_request

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "when the :group_ci_cd_analytics feature isn't licensed" do
      before do
        stub_licensed_features(group_ci_cd_analytics: false)
      end

      it_behaves_like 'returns a 403'
    end

    [
      {
        tab_param: '',
        event: 'g_analytics_ci_cd_release_statistics'
      },
      {
        tab_param: 'release-statistics',
        event: 'g_analytics_ci_cd_release_statistics'
      },
      {
        tab_param: 'deployment-frequency',
        event: 'g_analytics_ci_cd_deployment_frequency'
      },
      {
        tab_param: 'lead-time',
        event: 'g_analytics_ci_cd_lead_time'
      },
      {
        tab_param: 'time-to-restore-service',
        event: 'g_analytics_ci_cd_time_to_restore_service'
      },
      {
        tab_param: 'change-failure-rate',
        event: 'g_analytics_ci_cd_change_failure_rate'
      }
    ].each do |tab|
      it_behaves_like 'tracking unique visits', :show do
        let(:request_params) { { group_id: group.to_param, tab: tab[:tab_param] } }
        let(:target_id) { tab[:event] }
      end
    end
  end
end
