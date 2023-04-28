# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view usage quotas', feature_category: :consumables_cost_management do
  describe 'GET /groups/:group/-/usage_quotas' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:user) { create(:user) }

    before_all do
      namespace.add_owner(user)
    end

    before do
      login_as(user)
    end

    context 'when storage size is over limit' do
      subject { get group_usage_quotas_path(namespace) }

      it_behaves_like 'namespace storage limit alert'
    end
  end
end
