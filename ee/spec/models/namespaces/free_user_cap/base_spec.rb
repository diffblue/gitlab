# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Base, :saas do
  let_it_be(:namespace) { create(:group_with_plan, :private, plan: :free_plan) }

  describe '#enforce_cap?' do
    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    it 'raises an error for feature enabled definition' do
      expect { described_class.new(namespace).enforce_cap? }.to raise_error(NotImplementedError)
    end
  end

  describe '#users_count' do
    let(:test_class) do
      Class.new(described_class) do
        private

        def limit
          5
        end
      end
    end

    subject(:users_count) { test_class.new(namespace).users_count }

    it { is_expected.to eq(0) }

    it 'raises an error for limit definition' do
      expect { described_class.new(namespace).users_count }.to raise_error(NotImplementedError)
    end

    context 'when invoked with request cache', :request_store do
      it 'caches the result for the same namespace' do
        expect(users_count).to eq(0)

        namespace.add_developer(create(:user))

        expect(users_count).to eq(0)
      end

      it 'does not cache the result for the same namespace' do
        instance = test_class.new(namespace)

        expect(instance.users_count(cache: false)).to eq(0)

        namespace.add_developer(create(:user))

        expect(instance.users_count(cache: false)).to eq(1)
      end
    end
  end
end
