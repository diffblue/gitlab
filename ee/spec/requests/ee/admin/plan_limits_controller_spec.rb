# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlanLimitsController, :enable_admin_mode,
  type: :request,
  feature_category: :consumables_cost_management do
  describe 'GET #index' do
    subject(:get_index) { get admin_plan_limits_path }

    shared_examples 'unsuccessful request', status: :not_found do
      it 'is unsuccessful' do
        get_index

        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'with an admin user' do
      let_it_be(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when on .com', :saas do
        before do
          stub_ee_application_setting(should_check_namespace_plan: true)
        end

        it 'is successful' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when not on .com' do
        it_behaves_like 'unsuccessful request'
      end

      context 'when :plan_limits_admin_dashboard is disabled' do
        before do
          stub_feature_flags(plan_limits_admin_dashboard: false)
        end

        it_behaves_like 'unsuccessful request'
      end
    end

    context 'with non-admin user' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it_behaves_like 'unsuccessful request'
    end

    context 'with no user' do
      it_behaves_like 'unsuccessful request', status: :redirect
    end
  end
end
