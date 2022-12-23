# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Base, :saas do
  let_it_be(:namespace, refind: true) { create(:group_with_plan, :private, plan: :free_plan) }

  describe '#enforce_cap?' do
    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    it 'raises an error for feature enabled definition' do
      expect { described_class.new(namespace).enforce_cap? }.to raise_error(NotImplementedError)
    end

    context 'with storage limit considerations' do
      subject(:test_class) do
        Class.new(described_class) do
          private

          def feature_enabled?
            true
          end
        end
      end

      it 'is enforced when below storage limit' do
        expect(test_class.new(namespace)).to be_enforce_cap
      end

      it 'is not enforced when above storage limit' do
        limit = 100
        create(:plan_limits, plan: namespace.gitlab_subscription.hosted_plan, storage_size_limit: limit)
        create(:namespace_root_storage_statistics, namespace: namespace, storage_size: (limit + 1).megabytes)

        expect(test_class.new(namespace)).not_to be_enforce_cap
      end
    end
  end

  describe '#users_count' do
    subject(:users_count) { described_class.new(namespace).users_count }

    it { is_expected.to eq(0) }

    context 'with database limit considerations' do
      using RSpec::Parameterized::TableSyntax

      where(:dashboard_limit, :dashboard_notification_limit, :dashboard_enforcement_limit, :result) do
        1 | 2 | 3 | 4
        1 | 6 | 2 | 7
        7 | 2 | 1 | 8
        5 | 5 | 5 | 6
      end

      before do
        stub_ee_application_setting(dashboard_limit: dashboard_limit)
        stub_ee_application_setting(dashboard_notification_limit: dashboard_notification_limit)
        stub_ee_application_setting(dashboard_enforcement_limit: dashboard_enforcement_limit)
      end

      with_them do
        specify do
          expect(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).with(namespace, result).and_call_original

          users_count
        end
      end
    end

    context 'when invoked with request cache', :request_store do
      it 'caches the result for the same namespace' do
        expect(users_count).to eq(0)

        namespace.add_developer(create(:user))

        expect(users_count).to eq(0)
      end

      it 'does not cache the result for the same namespace' do
        instance = described_class.new(namespace)

        expect(instance.users_count(cache: false)).to eq(0)

        namespace.add_developer(create(:user))

        expect(instance.users_count(cache: false)).to eq(1)
      end
    end
  end
end
