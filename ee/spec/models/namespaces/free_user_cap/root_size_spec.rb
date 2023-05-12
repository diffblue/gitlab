# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::RootSize, :saas, feature_category: :experimentation_conversion do
  let_it_be(:namespace) { create(:group_with_plan, :private, plan: :free_plan) }
  let_it_be(:plan_limits) do
    create(:plan_limits, plan: namespace.gitlab_subscription.hosted_plan, storage_size_limit: 100)
  end

  let(:model) { described_class.new(namespace) }
  let(:current_size) { 50.megabytes }

  before do
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
end
