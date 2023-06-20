# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view usage quotas', feature_category: :consumables_cost_management do
  describe 'GET /groups/:group/-/usage_quotas' do
    subject { get group_usage_quotas_path(namespace) }

    let_it_be(:namespace) { create(:group) }
    let_it_be(:user) { create(:user) }

    before_all do
      namespace.add_owner(user)
    end

    before do
      login_as(user)
    end

    context 'when storage size is over limit' do
      it_behaves_like 'namespace storage limit alert'
    end

    context 'with enable_hamilton_in_usage_quotas_ui feature flag' do
      context 'when enabled' do
        before do
          stub_feature_flags(enable_hamilton_in_usage_quotas_ui: namespace)
        end

        it 'sets the feature flag to true' do
          subject

          expect(response.body).to have_pushed_frontend_feature_flags(enableHamiltonInUsageQuotasUi: true)
        end
      end

      context 'when disabled' do
        before do
          stub_feature_flags(enable_hamilton_in_usage_quotas_ui: false)
        end

        it 'sets the feature flag false' do
          subject

          expect(response.body).to have_pushed_frontend_feature_flags(enableHamiltonInUsageQuotasUi: false)
        end
      end
    end
  end
end
