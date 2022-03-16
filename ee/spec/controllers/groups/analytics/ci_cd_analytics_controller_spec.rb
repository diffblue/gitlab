# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CiCdAnalyticsController do
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
  end
end
