# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::RootSize, :saas, feature_category: :measurement_and_locking do
  let_it_be(:namespace, refind: true) { create(:group_with_plan, :private, plan: :free_plan) }

  let(:model) { described_class.new(namespace) }
  let(:current_size) { 50.megabytes }

  before do
    create(:plan_limits, plan: namespace.gitlab_subscription.hosted_plan, storage_size_limit: 100)
    create(:namespace_root_storage_statistics, namespace: namespace, storage_size: current_size)
  end

  describe '#above_size_limit?' do
    let(:disable_storage_check?) { false }

    subject { model.above_size_limit? }

    before do
      stub_feature_flags(free_user_cap_without_storage_check: disable_storage_check?)
    end

    context 'when below limit' do
      it { is_expected.to eq(false) }
    end

    context 'when above limit' do
      let(:current_size) { 101.megabytes }

      before do
        # proves local class override method takes effect
        allow(namespace).to receive(:temporary_storage_increase_enabled?).and_return(true)
        allow(model).to receive(:enforce_limit?).and_return(false)
      end

      context 'when valid for enforcement' do
        it { is_expected.to eq(true) }
      end

      context 'when not valid for enforcement' do
        let(:disable_storage_check?) { true }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#limit' do
    subject { model.limit }

    context 'when there is additional purchased storage and a plan' do
      before do
        namespace.update!(additional_purchased_storage_size: 10_000)
      end

      it { is_expected.to eq(10_100.megabytes) }
    end

    context 'when there is no additional purchased storage' do
      before do
        namespace.update!(additional_purchased_storage_size: 0)
      end

      it { is_expected.to eq(100.megabytes) }
    end

    context 'with cached values', :use_clean_rails_memory_store_caching do
      it 'caches the value' do
        key = described_class::LIMIT_CACHE_NAME

        subject

        expect(Rails.cache.read(['namespaces', namespace.id, key])).to eq(100.megabytes)
      end
    end
  end
end
