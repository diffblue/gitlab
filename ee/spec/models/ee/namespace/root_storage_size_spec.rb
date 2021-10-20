# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Namespace::RootStorageSize, :saas do
  let(:namespace) { create(:namespace) }
  let(:current_size) { 50.megabytes }
  let(:model) { described_class.new(namespace) }
  let(:create_statistics) { create(:namespace_root_storage_statistics, namespace: namespace, storage_size: current_size)}
  let_it_be(:ultimate_plan, reload: true) { create(:ultimate_plan) }
  let_it_be(:plan_limits, reload: true) { create(:plan_limits, plan: ultimate_plan, storage_size_limit: 100) }

  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan) }

  before do
    create_statistics
  end

  describe '#above_size_limit?' do
    subject { model.above_size_limit? }

    before do
      allow(namespace).to receive(:temporary_storage_increase_enabled?).and_return(false)
    end

    context 'when limit enforcement is off' do
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
          plan_limits.update!(storage_size_limit: 0)
          namespace.update!(additional_purchased_storage_size: 0)
        end

        it { is_expected.to eq(false) }
      end

      context 'when below limit' do
        it { is_expected.to eq(false) }
      end

      context 'when above limit' do
        let(:current_size) { 101.megabytes }

        context 'when temporary storage increase is disabled' do
          it { is_expected.to eq(true) }
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
        plan_limits.update!(storage_size_limit: 0)
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

    context 'caches values', :use_clean_rails_memory_store_caching do
      let(:key) { 'root_storage_current_size' }

      it 'caches the value' do
        subject

        expect(Rails.cache.read(['namespaces', namespace.id, key])).to eq(current_size)
      end
    end
  end

  describe '#limit' do
    subject { model.limit }

    context 'when there is additional purchased storage and a plan' do
      before do
        plan_limits.update!(storage_size_limit: 15_000)
        namespace.update!(additional_purchased_storage_size: 10_000)
      end

      it { is_expected.to eq(25_000.megabytes) }
    end

    context 'when there is no additionl purchased storage' do
      before do
        plan_limits.update!(storage_size_limit: 15_000)
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(15_000.megabytes) }
    end

    context 'when there is no additional purchased storage or plan limit set' do
      before do
        plan_limits.update!(storage_size_limit: 0)
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(0) }
    end

    context 'caches values', :use_clean_rails_memory_store_caching do
      let(:key) { 'root_storage_size_limit' }

      before do
        plan_limits.update!(storage_size_limit: 70_000)
        namespace.update!(additional_purchased_storage_size: 34_000)
      end

      it 'caches the value' do
        subject

        expect(Rails.cache.read(['namespaces', namespace.id, key])).to eq(104_000.megabytes)
      end
    end
  end

  describe '#enforce_limit?' do
    subject { model.enforce_limit? }

    around do |example|
      travel_to(current_date) { example.run }
    end

    context 'when current date is before enforcement date' do
      let(:current_date) { described_class::ENFORCEMENT_DATE - 1.day }

      it { is_expected.to eq(false) }
    end

    context 'when current date is on or after enforcement date' do
      let(:current_date) { described_class::ENFORCEMENT_DATE }

      context 'when no subscription is found for namespace' do
        before do
          subscription.destroy!
        end

        it { is_expected.to eq(true) }
      end

      context 'when subscription is for a free plan' do
        let!(:subscription) do
          create(:gitlab_subscription, namespace: namespace, hosted_plan: create(:free_plan))
        end

        it { is_expected.to eq(true) }
      end

      context 'when subscription is for a paid plan' do
        before do
          allow(subscription).to receive(:start_date).and_return(start_date)
        end

        context 'when subscription start date is before effective date' do
          let(:start_date) { described_class::EFFECTIVE_DATE - 1.day }

          it { is_expected.to eq(false) }
        end

        context 'when subscription start date is on or after effective date' do
          let(:start_date) { described_class::EFFECTIVE_DATE }

          it { is_expected.to eq(true) }
        end
      end
    end
  end
end
