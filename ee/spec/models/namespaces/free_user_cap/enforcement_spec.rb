# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Enforcement, :saas, feature_category: :experimentation_conversion do
  let_it_be(:namespace, reload: true) { create(:group_with_plan, :private, plan: :free_plan) }

  let(:dashboard_limit_enabled) { true }

  before do
    stub_ee_application_setting(dashboard_limit_enabled: dashboard_limit_enabled)
  end

  shared_context 'with net new namespace' do
    let(:enforcement_date) { Date.today }
    let_it_be(:namespace) do
      travel_to(Date.today + 2.days) do
        create(:group_with_plan, :private, plan: :free_plan)
      end
    end
  end

  describe '#over_limit?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }

    subject(:over_limit?) { described_class.new(namespace).over_limit? }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be false }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'with updating dashboard enforcement_at and notification_at fields', :use_clean_rails_redis_caching do
        context 'when cache has expired or does not exist' do
          context 'when under the limit' do
            let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

            it 'updates the database for non enforcement' do
              time = Time.current
              namespace.namespace_details.update!(dashboard_enforcement_at: time)

              expect do
                expect(over_limit?).to be(false)
              end.to change { namespace.namespace_details.dashboard_enforcement_at }.from(time).to(nil)
            end

            it 'does not blank out dashboard_notification_at' do
              namespace.namespace_details.update!(dashboard_notification_at: Time.current)

              expect do
                expect(over_limit?).to be(false)
              end.to not_change(namespace.namespace_details, :dashboard_enforcement_at)
                       .and(not_change(namespace.namespace_details, :dashboard_notification_at))
            end
          end

          context 'when over the limit' do
            it 'updates the database for enforcement' do
              freeze_time do
                expect do
                  expect(over_limit?).to be(true)
                end.to change { namespace.namespace_details.dashboard_enforcement_at }.from(nil).to(Time.current)
              end
            end

            it 'blanks out dashboard_notification_at' do
              time = Time.current
              namespace.namespace_details.update!(dashboard_notification_at: time)

              expect do
                expect(over_limit?).to be(true)
              end.to change { namespace.namespace_details.dashboard_notification_at }.from(time).to(nil)
            end

            it 'does not update dashboard_notification_at field needlessly' do
              expect(namespace.namespace_details).not_to receive(:update).with(dashboard_notification_at: nil)

              expect(over_limit?).to be(true)
            end

            context 'when dashboard_enforcement_at is already set' do
              it 'does not update dashboard_notification_at field needlessly or update dashboard_enforcement_at' do
                namespace.namespace_details.update!(dashboard_enforcement_at: Time.current)

                expect(namespace.namespace_details).not_to receive(:update)

                expect do
                  expect(over_limit?).to be(true)
                end.to not_change(namespace.namespace_details, :dashboard_enforcement_at)
                         .and(not_change(namespace.namespace_details, :dashboard_notification_at))
              end
            end
          end
        end

        context 'when cache exists' do
          before do
            over_limit?
          end

          it 'does not update the database' do
            namespace.namespace_details.update!(dashboard_enforcement_at: nil)

            expect(namespace.namespace_details).not_to receive(:update)

            expect do
              expect(over_limit?).to be(true)
            end.not_to change { namespace.namespace_details.dashboard_enforcement_at }
          end
        end
      end

      context 'when under the number of free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

        it { is_expected.to be false }
      end

      context 'when at the same number as the free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

        it { is_expected.to be false }
      end

      context 'when over the number of free users limit' do
        context 'when it is a free plan' do
          it { is_expected.to be true }

          context 'when the namespace is not a group' do
            let_it_be(:namespace) do
              namespace = create(:user).namespace
              create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
              namespace
            end

            it { is_expected.to be false }
          end

          context 'when the namespace is public' do
            before do
              namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
            end

            it { is_expected.to be false }
          end

          context 'when the namespace is over storage limit' do
            before do
              allow_next_instance_of(::Namespaces::FreeUserCap::RootSize, namespace) do |instance|
                allow(instance).to receive(:above_size_limit?).and_return(true)
              end
            end

            it { is_expected.to be false }
          end
        end

        context 'when it is a non free plan' do
          let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

          it { is_expected.to be false }
        end

        context 'when no plan exists' do
          let_it_be(:namespace) { create(:group, :private) }

          it { is_expected.to be true }

          context 'when namespace is public' do
            let_it_be(:namespace) { create(:group, :public) }

            it { is_expected.to be false }
          end
        end

        context 'when dashboard_limit_enabled is false' do
          let(:dashboard_limit_enabled) { false }

          it { is_expected.to be false }
        end
      end

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be true }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be true }
        end
      end
    end

    context 'with benchmarks' do
      it 'shows with and without database update' do
        # Run with:
        #   BENCHMARK=1 rspec ee/spec/models/namespaces/free_user_cap/enforcement_spec.rb
        skip('Skipped. To run set env variable BENCHMARK=1') unless ENV.key?('BENCHMARK')

        require 'benchmark/ips'

        puts "\n--> Benchmarking over limit with database updating and without\n"

        Benchmark.ips do |x|
          x.report('with database update') do
            ::Namespaces::FreeUserCap::Enforcement.new(namespace).over_limit?
          end
          x.report('without database update') do
            ::Namespaces::FreeUserCap::Enforcement.new(namespace).over_limit?(update_database: false)
          end
          x.compare!
        end
      end
    end
  end

  describe '#reached_limit?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }

    subject(:reached_limit?) { described_class.new(namespace).reached_limit? }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be true }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be false }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when under the number of free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

        it { is_expected.to be false }
      end

      context 'when at the same number as the free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

        it { is_expected.to be true }
      end

      context 'when over the number of free users limit' do
        context 'when it is a free plan' do
          it { is_expected.to be true }

          context 'when the namespace is not a group' do
            let_it_be(:namespace) do
              namespace = create(:user).namespace
              create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
              namespace
            end

            it { is_expected.to be false }
          end
        end

        context 'when it is a non free plan' do
          let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

          it { is_expected.to be false }
        end

        context 'when no plan exists' do
          let_it_be(:namespace) { create(:group, :private) }

          it { is_expected.to be true }

          context 'when namespace is public' do
            let_it_be(:namespace) { create(:group, :public) }

            it { is_expected.to be false }
          end
        end

        context 'when dashboard_limit_enabled is false' do
          let(:dashboard_limit_enabled) { false }

          it { is_expected.to be false }
        end
      end

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be true }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be true }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be true }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#at_limit?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }

    subject(:at_limit?) { described_class.new(namespace).at_limit? }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }
    end

    context 'when :free_user_cap is enabled' do
      let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be false }
            end

            context 'when at the dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be true }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be false }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be false }
        end
      end
    end
  end

  describe '#seat_available?' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }
    let_it_be(:user) { create(:user) }

    subject(:seat_available?) { described_class.new(namespace).seat_available?(user) }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
    end

    shared_examples 'user is an already existing member in the namespace' do
      before do
        build(:group_member, :owner, source: namespace, user: user).tap do |record|
          record.save!(validate: false)
        end
      end

      it { is_expected.to be true }
    end

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be true }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be true }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be false }
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be true }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be true }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when under the number of free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

        it { is_expected.to be true }

        context 'when invoked with request cache', :request_store do
          it 'responds correctly between calls when no seats are exhausted' do
            expect(described_class.new(namespace).seat_available?(user)).to be(true)

            allow(::Namespaces::FreeUserCap::UsersFinder)
              .to receive(:count).and_return({ user_ids: Namespaces::FreeUserCap.dashboard_limit })

            expect(described_class.new(namespace).seat_available?(user)).to be(false)
          end
        end
      end

      context 'when at the same number as the free users limit' do
        let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit }

        it { is_expected.to be false }

        it_behaves_like 'user is an already existing member in the namespace'
      end

      context 'when over the number of free users limit' do
        context 'when it is a free plan' do
          it { is_expected.to be false }

          it_behaves_like 'user is an already existing member in the namespace'

          context 'when the namespace is not a group' do
            let_it_be(:namespace) do
              namespace = create(:user).namespace
              create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
              namespace
            end

            it { is_expected.to be true }
          end
        end

        context 'when it is a non free plan' do
          let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

          it { is_expected.to be true }
        end

        context 'when no plan exists' do
          let_it_be(:namespace) { create(:group, :private) }

          it { is_expected.to be false }

          context 'when namespace is public' do
            let_it_be(:namespace) { create(:group, :public) }

            it { is_expected.to be true }
          end
        end

        context 'when dashboard_limit_enabled is false' do
          let(:dashboard_limit_enabled) { false }

          it { is_expected.to be true }
        end
      end

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_ee_application_setting(dashboard_limit: 3)
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            context 'when under the dashboard_limit' do
              let(:free_plan_members_count) { 2 }

              it { is_expected.to be true }
            end

            context 'when at dashboard_limit' do
              let(:free_plan_members_count) { 3 }

              it { is_expected.to be false }

              it_behaves_like 'user is an already existing member in the namespace'
            end

            context 'when over the dashboard_limit' do
              let(:free_plan_members_count) { 4 }

              it { is_expected.to be false }

              it_behaves_like 'user is an already existing member in the namespace'
            end
          end

          context 'when :free_user_cap_new_namespaces is disabled it honors existing namespace logic' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated it honors existing namespace logic' do
          it { is_expected.to be false }
        end
      end
    end
  end

  describe '#enforce_cap?' do
    subject(:enforce_cap?) { described_class.new(namespace).enforce_cap? }

    context 'when :free_user_cap is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it { is_expected.to be false }

      context 'with a net new namespace' do
        include_context 'with net new namespace'

        context 'when enforcement date is populated' do
          before do
            stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          end

          context 'when :free_user_cap_new_namespaces is enabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: true)
            end

            it { is_expected.to be true }
          end

          context 'when :free_user_cap_new_namespaces is disabled' do
            before do
              stub_feature_flags(free_user_cap_new_namespaces: false)
            end

            it { is_expected.to be false }
          end
        end

        context 'when enforcement date is not populated' do
          it { is_expected.to be false }
        end
      end
    end

    context 'when :free_user_cap is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when it is a free plan' do
        it { is_expected.to be true }

        context 'when namespace is public' do
          let_it_be(:namespace) { create(:group, :public) }

          it { is_expected.to be false }
        end
      end

      context 'when it is a non free plan' do
        let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }

        it { is_expected.to be false }
      end

      context 'when no plan exists' do
        let_it_be(:namespace) { create(:group, :private) }

        it { is_expected.to be true }

        context 'when namespace is public' do
          let_it_be(:namespace) { create(:group, :public) }

          it { is_expected.to be false }
        end
      end

      context 'when dashboard_limit_enabled is false' do
        let(:dashboard_limit_enabled) { false }

        it { is_expected.to be false }
      end
    end
  end

  describe '#close_to_dashboard_limit?' do
    let(:free_plan_members_count) { 1 }

    subject(:close_to_dashboard_limit?) { described_class.new(namespace).close_to_dashboard_limit? }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
      stub_ee_application_setting(dashboard_limit: 3)
    end

    it { is_expected.to be false }

    context 'with a net new namespace' do
      include_context 'with net new namespace'

      context 'when enforcement date is not populated' do
        it { is_expected.to be false }
      end

      context 'when enforcement date is populated' do
        before do
          stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
        end

        context 'when :free_user_cap_new_namespaces is enabled' do
          before do
            stub_feature_flags(free_user_cap_new_namespaces: true)
          end

          context 'when far below the dashboard limit' do
            let(:free_plan_members_count) { 0 }

            it { is_expected.to be false }
          end

          context 'when close to the dashboard limit' do
            let(:free_plan_members_count) { 1 }

            it { is_expected.to be true }
          end

          context 'when at dashboard_limit' do
            let(:free_plan_members_count) { 3 }

            it { is_expected.to be false }
          end

          context 'when over the dashboard_limit' do
            let(:free_plan_members_count) { 4 }

            it { is_expected.to be false }
          end
        end

        context 'when :free_user_cap_new_namespaces is disabled' do
          let(:free_plan_members_count) { 1 }

          before do
            stub_feature_flags(free_user_cap_new_namespaces: false)
          end

          it { is_expected.to be false }
        end
      end
    end
  end

  describe '#remaining_seats' do
    subject(:remaining_seats) { described_class.new(namespace).remaining_seats }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
      stub_ee_application_setting(dashboard_enforcement_limit: 2)
    end

    context 'when under the number of free users limit' do
      let(:free_plan_members_count) { 1 }

      it { is_expected.to eq(1) }
    end

    context 'when at the number of free users limit' do
      let(:free_plan_members_count) { 2 }

      it { is_expected.to eq(0) }
    end

    context 'when over the number of free users limit' do
      let(:free_plan_members_count) { 3 }

      it { is_expected.to eq(0) }
    end

    context 'when on a new net namespace' do
      include_context 'with net new namespace'

      let(:free_plan_members_count) { 1 }

      before do
        stub_ee_application_setting(dashboard_limit: 2)
      end

      it { is_expected.to eq(1) }
    end
  end

  describe '#git_check_over_limit!' do
    let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit + 1 }

    subject(:git_check_over_limit!) { described_class.new(namespace).git_check_over_limit!(StandardError) }

    before do
      allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_plan_members_count })
    end

    context 'when not over the user limit' do
      let(:free_plan_members_count) { Namespaces::FreeUserCap.dashboard_limit - 1 }

      it { is_expected.to be_nil }
    end

    context 'when over the user limit' do
      let(:over_user_limit_message) { /Your top-level group is over the user limit/ }
      let(:over_combined_limit_message) { /Your top-level group is over the user and storage limits/ }

      it 'raises an error for over user limit' do
        expect { git_check_over_limit! }.to raise_error(StandardError, over_user_limit_message)
      end

      context 'when over storage and user limit' do
        before do
          allow(namespace).to receive(:over_storage_limit?).and_return(true)
        end

        it 'raises an error for over user and storage limit' do
          expect do
            described_class.new(namespace).git_check_over_limit!(StandardError)
          end.to raise_error(StandardError, over_combined_limit_message)
        end
      end

      context 'when block is provided for storage limit' do
        context 'when block for storage limit evaluates to true' do
          it 'raises an error for over user and storage limit' do
            expect do
              described_class.new(namespace).git_check_over_limit!(StandardError) { true }
            end.to raise_error(StandardError, over_combined_limit_message)
          end
        end

        context 'when block for storage limit evaluates to false' do
          it 'raises an error for over user limit' do
            expect do
              described_class.new(namespace).git_check_over_limit!(StandardError) { false }
            end.to raise_error(StandardError, over_user_limit_message)
          end
        end
      end
    end
  end
end
