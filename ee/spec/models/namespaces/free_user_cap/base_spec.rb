# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Base, :saas, feature_category: :experimentation_conversion do
  let_it_be(:namespace, refind: true) { create(:group_with_plan, :private, plan: :free_plan) }

  describe '#enforce_cap?' do
    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    it 'raises an error for feature enabled definition' do
      expect { described_class.new(namespace).enforce_cap? }.to raise_error(NotImplementedError)
    end

    context 'with storage limit considerations' do
      let(:disable_storage_check?) { false }

      subject(:test_class) do
        Class.new(described_class) do
          private

          def feature_enabled?
            true
          end
        end
      end

      before do
        stub_feature_flags(free_user_cap_without_storage_check: disable_storage_check?)
      end

      it 'is enforced when below storage limit' do
        expect(test_class.new(namespace)).to be_enforce_cap
      end

      context 'when above storage limit' do
        before_all do
          limit = 100
          create(:plan_limits, plan: namespace.gitlab_subscription.hosted_plan, storage_size_limit: limit)
          create(:namespace_root_storage_statistics, namespace: namespace, storage_size: (limit + 1).megabytes)
        end

        it 'is not enforced' do
          expect(test_class.new(namespace)).not_to be_enforce_cap
        end

        context 'with storage check disabled' do
          let(:disable_storage_check?) { true }

          it 'is enforced' do
            expect(test_class.new(namespace)).to be_enforce_cap
          end
        end
      end
    end

    context 'when invoked with request cache', :request_store do
      subject(:test_class) do
        Class.new(described_class) do
          private

          def feature_enabled?
            true
          end
        end
      end

      before do
        test_class.new(namespace).enforce_cap?
      end

      it 'enforces cap' do
        expect(test_class.new(namespace)).to be_enforce_cap
      end

      it 'does not perform extra work when enforce_cap has been invoked before' do
        expect(::Gitlab::CurrentSettings).not_to receive(:dashboard_limit_enabled?)

        test_class.new(namespace).enforce_cap?
      end

      it 'benchmarks with and without cache' do
        # Run with:
        #   BENCHMARK=1 rspec ee/spec/models/namespaces/free_user_cap/base_spec.rb
        skip('Skipped. To run set env variable BENCHMARK=1') unless ENV.key?('BENCHMARK')

        require 'benchmark/ips'

        puts "\n--> Benchmarking enforce cap with request caching and without\n"

        Benchmark.ips do |x|
          x.report('without cache') do
            test_class.new(namespace).enforce_cap?(cache: false)
          end
          x.report('with cache') do
            test_class.new(namespace).enforce_cap?(cache: true)
          end
          x.compare!
        end
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
