# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::RootSize, :saas, feature_category: :consumables_cost_management do
  include NamespaceStorageHelpers
  using RSpec::Parameterized::TableSyntax

  let(:namespace) { create(:group) }
  let(:current_size) { 50.megabytes }
  let(:model) { described_class.new(namespace) }
  let(:create_statistics) do
    create(:namespace_root_storage_statistics, namespace: namespace, storage_size: current_size)
  end

  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan) }

  let_it_be(:ultimate_plan, reload: true) { create(:ultimate_plan) }
  let_it_be(:plan_limits, reload: true) { create(:plan_limits, plan: ultimate_plan) }
  let_it_be(:free_plan) { create(:free_plan) }

  before do
    create_statistics
    set_enforcement_limit(namespace, megabytes: 100)
  end

  describe '#above_size_limit?' do
    subject(:above_size_limit?) { model.above_size_limit? }

    before do
      allow(namespace).to receive(:temporary_storage_increase_enabled?).and_return(false)
    end

    context 'when limit enforcement is off' do
      let(:current_size) { 101.megabytes }

      before do
        allow(model).to receive(:enforce_limit?).and_return(false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when limit enforcement is on' do
      before do
        allow(model).to receive(:enforce_limit?).and_return(true)
      end

      context 'when limit is 0' do
        before do
          set_enforcement_limit(namespace, megabytes: 0)
          namespace.update!(additional_purchased_storage_size: 0)
        end

        it { is_expected.to eq(false) }
      end

      context 'when below limit' do
        it { is_expected.to eq(false) }
      end

      context 'when above limit', :use_clean_rails_memory_store_caching do
        let(:current_size) { 101.megabytes }

        context 'when temporary storage increase is disabled' do
          let(:namespace_limit) { namespace.namespace_limit }

          it { is_expected.to eq(true) }

          context 'when tracking the first enforcement for a namespace' do
            context 'when the namespace has never been above the limit before', :freeze_time do
              it 'updates the first_enforced_at timestamp' do
                expect { above_size_limit? }.to change { namespace_limit.first_enforced_at }

                namespace_limit.reload

                expect(namespace_limit.first_enforced_at).to be_like_time(Time.current)
              end

              context 'when cache exists' do
                before do
                  above_size_limit?
                end

                it 'does not update the database' do
                  namespace_limit.update!(first_enforced_at: nil)

                  expect(namespace_limit).not_to receive(:update)

                  expect do
                    expect(above_size_limit?).to be(true)
                  end.not_to change { namespace_limit.first_enforced_at }
                end
              end
            end

            context 'when the namespace has been above the limit before' do
              before do
                namespace_limit.update!(first_enforced_at: Time.current)
              end

              context 'with no cache' do
                it 'does not update the timestamp' do
                  expect { above_size_limit? }.not_to change { namespace_limit.first_enforced_at }
                end
              end

              context 'when cache exists' do
                before do
                  above_size_limit?
                end

                it 'does not update the database' do
                  namespace_limit.update!(first_enforced_at: nil)

                  expect(namespace_limit).not_to receive(:update)

                  expect do
                    expect(above_size_limit?).to be(true)
                  end.not_to change { namespace_limit.first_enforced_at }
                end
              end
            end
          end

          context 'when tracking the last enforcement for a namespace' do
            context 'with no cache' do
              it 'updates the last_enforced_at timestamp' do
                expect { above_size_limit? }.to change { namespace_limit.last_enforced_at }
              end
            end

            context 'when cache exists' do
              before do
                above_size_limit?
              end

              it 'does not update the database' do
                expect(namespace_limit).not_to receive(:update)

                expect do
                  expect(above_size_limit?).to be(true)
                end.not_to change { namespace_limit.last_enforced_at }
              end
            end
          end
        end

        context 'when temporary storage increase is enabled' do
          before do
            allow(namespace).to receive(:temporary_storage_increase_enabled?).and_return(true)
          end

          it { is_expected.to eq(false) }
        end
      end
    end
  end

  describe '#usage_ratio' do
    subject { model.usage_ratio }

    it { is_expected.to eq(0.5) }

    context 'when limit is 0' do
      before do
        set_enforcement_limit(namespace, megabytes: 0)
      end

      it { is_expected.to eq(0) }
    end

    context 'when there are no root_storage_statistics' do
      let(:create_statistics) { nil }

      it { is_expected.to eq(0) }
    end
  end

  describe '#current_size' do
    subject { model.current_size }

    it { is_expected.to eq(current_size) }

    context 'with cached values', :use_clean_rails_memory_store_caching do
      let(:key) { 'root_storage_current_size' }

      it 'caches the value' do
        subject

        expect(Rails.cache.read(['namespaces', namespace.id, key])).to eq(current_size)
      end
    end

    context 'when it is a subgroup of the namespace' do
      let(:model) { described_class.new(create(:group, parent: namespace)) }

      it { is_expected.to eq(current_size) }
    end

    context 'when there are no root_storage_statistics' do
      let(:create_statistics) { nil }

      it 'returns zero' do
        expect(model.current_size).to eq(0)
      end
    end

    context 'with fork storage sizes' do
      let(:create_statistics) do
        create(:namespace_root_storage_statistics, namespace: namespace, storage_size: 1000,
          public_forks_storage_size: 100)
      end

      before do
        stub_ee_application_setting(check_namespace_plan: true)
        stub_ee_application_setting(namespace_storage_forks_cost_factor: 0.05)
      end

      it 'returns the cost factored storage size' do
        expect(model.current_size).to eq(905)
      end
    end
  end

  describe '#limit' do
    before do
      set_enforcement_limit(namespace, megabytes: 15_000)
    end

    subject { model.limit }

    context 'when there is additional purchased storage and a plan' do
      before do
        namespace.update!(additional_purchased_storage_size: 10_000)
      end

      it { is_expected.to eq(25_000.megabytes) }
    end

    context 'when there is no additionl purchased storage' do
      before do
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(15_000.megabytes) }
    end

    context 'when there is no additional purchased storage or plan limit set' do
      before do
        set_enforcement_limit(namespace, megabytes: 0)
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(0) }
    end

    context 'with cached values', :use_clean_rails_memory_store_caching do
      let(:key) { 'root_storage_size_limit' }

      before do
        set_enforcement_limit(namespace, megabytes: 70_000)
        namespace.update!(additional_purchased_storage_size: 34_000)
      end

      it 'caches the value' do
        subject

        expect(Rails.cache.read(['namespaces', namespace.id, key])).to eq(104_000.megabytes)
      end
    end
  end

  describe '#used_storage_percentage' do
    where(:limit, :used, :expected_percentage) do
      0    | 0    | 0
      0    | 100  | 0
      100  | 0    | 0
      100  | 200  | 200
      1    | 0    | 0
      100  | 10   | 10
      100  | 77   | 77
      100  | 95   | 95
      100  | 99   | 99
      100  | 100  | 100
      1000 | 971  | 97
      8192 | 6144 | 75
      5120 | 3840 | 75
      5120 | 5118 | 99
    end

    with_them do
      it 'returns the percentage of remaining storage rounding down to the nearest integer' do
        set_enforcement_limit(namespace, megabytes: limit)
        set_used_storage(namespace, megabytes: used)

        expect(model.used_storage_percentage).to eq(expected_percentage)
      end
    end
  end

  describe '#remaining_storage_percentage' do
    where(:limit, :used, :expected_percentage) do
      0    | 0    | 100
      0    | 100  | 100
      100  | 0    | 100
      100  | 200  | 0
      1    | 0    | 100
      100  | 10   | 90
      100  | 77   | 23
      100  | 95   | 5
      100  | 99   | 1
      100  | 100  | 0
      1000 | 971  | 2
      8192 | 6144 | 25
      5120 | 3840 | 25
      5120 | 5118 | 0
    end

    with_them do
      it 'returns the percentage of remaining storage rounding down to the nearest integer' do
        set_enforcement_limit(namespace, megabytes: limit)
        set_used_storage(namespace, megabytes: used)

        expect(model.remaining_storage_percentage).to eq(expected_percentage)
      end
    end
  end

  describe '#remaining_storage_size' do
    where(:limit, :used, :expected_size) do
      0    | 0    | 0
      0    | 100  | 0
      100  | 0    | 100.megabytes
      100  | 200  | 0
      100  | 70   | 30.megabytes
      100  | 85   | 15.megabytes
      100  | 99   | 1.megabyte
      100  | 100  | 0
      1000 | 971  | 29.megabytes
      8192 | 6144 | 2048.megabytes
      5120 | 3840 | 1280.megabytes
      5120 | 5118 | 2.megabytes
    end

    with_them do
      it 'returns the remaining storage size in bytes' do
        set_enforcement_limit(namespace, megabytes: limit)
        set_used_storage(namespace, megabytes: used)

        expect(model.remaining_storage_size).to eq(expected_size)
      end
    end
  end

  describe '#enforce_limit?' do
    it 'delegates to Namespaces::Storage::Enforcement' do
      expect(::Namespaces::Storage::Enforcement).to receive(:enforce_limit?).with(namespace)

      model.enforce_limit?
    end
  end

  describe '#exceeded_size' do
    before do
      set_enforcement_limit(namespace, megabytes: 100)
    end

    context 'when given a parameter' do
      where(:change_size, :expected_excess_size) do
        150.megabytes | 100.megabytes
        60.megabytes  | 10.megabytes
        51.megabytes  | 1.megabyte
        50.megabytes  | 0
        10.megabytes  | 0
        0             | 0
      end

      with_them do
        it 'returns the size in bytes that the change exceeds the limit' do
          expect(model.exceeded_size(change_size)).to eq(expected_excess_size)
        end
      end
    end

    context 'without a parameter' do
      where(:current_size, :expected_excess_size) do
        0             | 0
        50.megabytes  | 0
        100.megabytes | 0
        101.megabytes | 1.megabyte
        170.megabytes | 70.megabytes
      end

      with_them do
        it 'returns the size in bytes that the current storage size exceeds the limit' do
          expect(model.exceeded_size).to eq(expected_excess_size)
        end
      end
    end
  end

  describe '#changes_will_exceed_size_limit?' do
    let(:project) { build_stubbed(:project, group: namespace) }

    before do
      stub_ee_application_setting(check_namespace_plan: true)
      stub_ee_application_setting(namespace_storage_forks_cost_factor: 0.1)
    end

    context 'when the changes will exceed the size limit' do
      where(:change_size) { [51.megabytes, 60.megabytes, 100.megabytes] }

      with_them do
        it 'returns true' do
          expect(model.changes_will_exceed_size_limit?(change_size, project)).to eq(true)
        end
      end
    end

    context 'when the changes will not exceed the size limit' do
      where(:change_size) { [0, 1.megabyte, 40.megabytes, 50.megabytes] }

      with_them do
        it 'returns false' do
          expect(model.changes_will_exceed_size_limit?(change_size, project)).to eq(false)
        end
      end
    end

    context 'when the current size exceeds the limit' do
      let(:current_size) { 101.megabytes }

      where(:change_size) { [0, 1.megabyte, 60.megabytes, 100.megabytes] }

      with_them do
        it 'returns true regardless of change_size' do
          expect(model.changes_will_exceed_size_limit?(change_size, project)).to eq(true)
        end
      end
    end

    context 'when storage size limit is 0' do
      before do
        set_enforcement_limit(namespace, megabytes: 0)
      end

      it 'returns false' do
        expect(model.changes_will_exceed_size_limit?(120.megabytes, project)).to eq(false)
      end
    end

    context 'with a project fork' do
      context 'in a paid namespace' do
        where(:visibility_level) { [:public, :internal, :private] }

        with_them do
          it 'applies a cost factor for forks to the changes size' do
            project_fork = build_fork(visibility_level)

            expect(model.changes_will_exceed_size_limit?(100.megabytes, project_fork)).to eq(false)
          end
        end
      end

      context 'in a free namespace' do
        let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: free_plan) }

        where(:visibility_level) { [:public, :internal] }

        with_them do
          it 'applies a cost factor for forks to the changes size' do
            project_fork = build_fork(visibility_level)

            expect(model.changes_will_exceed_size_limit?(100.megabytes, project_fork)).to eq(false)
          end
        end

        it 'does not apply a cost factor for forks to the changes size for a private fork' do
          project_fork = build_fork(:private)

          expect(model.changes_will_exceed_size_limit?(100.megabytes, project_fork)).to eq(true)
        end
      end
    end
  end

  describe '#enforcement_type' do
    it 'returns :namespace_storage_limit' do
      expect(model.enforcement_type).to eq(:namespace_storage_limit)
    end
  end

  def build_fork(visibility_level)
    project = build_stubbed(:project, group: namespace)
    fork_network = build_stubbed(:fork_network, root_project: project)
    project_fork = build_stubbed(:project, visibility_level, group: namespace, fork_network: fork_network)
    build_stubbed(:fork_network_member, project: project_fork,
      fork_network: fork_network, forked_from_project: project)

    project_fork
  end
end
