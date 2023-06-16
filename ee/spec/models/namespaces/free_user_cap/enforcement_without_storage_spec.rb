# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::EnforcementWithoutStorage, :saas, feature_category: :consumables_cost_management do
  include FreeUserCapHelpers

  let_it_be(:namespace) do
    create(:group_with_plan, :with_root_storage_statistics, :private, plan: :free_plan,
      name: 'over_users')
  end

  describe '#over_limit?' do
    subject do
      described_class.new(namespace).over_limit?
    end

    context 'when the namespace is not over the users limit' do
      before do
        enforce_free_user_caps
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when the namespace is over users limit' do
      before do
        exceed_user_cap(namespace)
        enforce_free_user_caps
      end

      it 'returns true' do
        is_expected.to eq(true)
      end
    end
  end
end
