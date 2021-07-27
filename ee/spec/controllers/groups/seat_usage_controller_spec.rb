# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SeatUsageController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  describe 'GET show' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
    end

    def get_show
      get :show, params: { group_id: group }
    end

    subject { response }

    context 'when authorized' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get_show

        is_expected.to have_gitlab_http_status(:ok)
        is_expected.to render_template(:show)
      end
    end

    context 'when unauthorized' do
      before do
        group.add_developer(user)
      end

      it 'renders 403 when user is not an owner' do
        get_show

        is_expected.to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
