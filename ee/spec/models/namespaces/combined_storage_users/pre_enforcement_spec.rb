# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::CombinedStorageUsers::PreEnforcement, :saas, feature_category: :consumables_cost_management do
  include NamespaceStorageHelpers
  include FreeUserCapHelpers

  describe '#over_both_limits?' do
    let(:klass) do
      Class.new do
        include Namespaces::CombinedStorageUsers::PreEnforcement
      end
    end

    let_it_be(:namespace) do
      create(:group_with_plan, :with_root_storage_statistics, :private, plan: :free_plan,
        name: 'over_storage_and_users')
    end

    subject do
      klass.new.over_both_limits?(namespace)
    end

    before do
      set_notification_limit(namespace, megabytes: 5_000)
      exceed_user_cap(namespace)
      enforce_free_user_caps
      stub_ee_application_setting(should_check_namespace_plan: true, automatic_purchased_storage_allocation: true)
    end

    context 'when the namespace is over both storage/users limits' do
      before do
        set_used_storage(namespace, megabytes: 6_000)
      end

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when the namespace is over only one limit' do
      before do
        set_used_storage(namespace, megabytes: 4_000)
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#over_user_limit?' do
    let(:klass) do
      Class.new do
        include Namespaces::CombinedStorageUsers::PreEnforcement
      end
    end

    let_it_be(:namespace) do
      create(:group_with_plan, :with_root_storage_statistics, :private, plan: :free_plan,
        name: 'over_users')
    end

    subject do
      klass.new.over_user_limit?(namespace)
    end

    context 'when the namespace is not users limit' do
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

  describe '#over_storage_limit?' do
    let(:klass) do
      Class.new do
        include Namespaces::CombinedStorageUsers::PreEnforcement
      end
    end

    let_it_be(:namespace) do
      create(:group_with_plan, :with_root_storage_statistics, :private, plan: :free_plan,
        name: 'over_storage')
    end

    subject do
      klass.new.over_storage_limit?(namespace)
    end

    before do
      set_notification_limit(namespace, megabytes: 5_000)
      stub_ee_application_setting(should_check_namespace_plan: true, automatic_purchased_storage_allocation: true)
    end

    context 'when the namespace is over storage limit' do
      before do
        set_used_storage(namespace, megabytes: 6_000)
      end

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when the namespace is not over storage limit' do
      before do
        set_used_storage(namespace, megabytes: 4_000)
      end

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end
end
