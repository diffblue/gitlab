# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::RootExcessSize do
  let(:namespace) { create(:group, additional_purchased_storage_size: additional_purchased_storage_size) }
  let(:total_repository_size_excess) { 50.megabytes }
  let(:additional_purchased_storage_size) { 100 }
  let(:model) { described_class.new(namespace) }
  let(:root_namespace) { namespace }

  before do
    allow(root_namespace).to receive(:total_repository_size_excess).and_return(total_repository_size_excess)
  end

  describe '#above_size_limit?' do
    subject { model.above_size_limit? }

    before do
      allow(model).to receive(:enforce_limit?) { enforce_limit }
    end

    context 'when limit enforcement is off' do
      let(:enforce_limit) { false }

      it { is_expected.to eq(false) }
    end

    context 'when limit enforcement is on' do
      let(:enforce_limit) { true }

      context 'when below limit' do
        it { is_expected.to eq(false) }
      end

      context 'when above limit' do
        let(:total_repository_size_excess) { 101.megabytes }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#usage_ratio' do
    subject { model.usage_ratio }

    it { is_expected.to eq(0.5) }

    context 'when limit is 0' do
      let(:additional_purchased_storage_size) { 0 }

      context 'when current size is greater than 0' do
        it { is_expected.to eq(1) }
      end

      context 'when current size is less than 0' do
        let(:total_repository_size_excess) { 0 }

        it { is_expected.to eq(0) }
      end
    end
  end

  describe '#current_size' do
    subject { model.current_size }

    it { is_expected.to eq(total_repository_size_excess) }

    context 'when it is a subgroup of the namespace' do
      let(:subgroup) { create(:group, parent: namespace) }
      let(:model) { described_class.new(subgroup) }
      let(:root_namespace) { subgroup.root_ancestor }

      it { is_expected.to eq(total_repository_size_excess) }
    end
  end

  describe '#limit' do
    subject { model.limit }

    context 'when there is additional purchased storage and a plan' do
      let(:additional_purchased_storage_size) { 10_000 }

      it { is_expected.to eq(10_000.megabytes) }
    end

    context 'when there is no additionl purchased storage' do
      let(:additional_purchased_storage_size) { 0 }

      it { is_expected.to eq(0.megabytes) }
    end
  end

  describe '#enforce_limit?' do
    it 'returns true if automatic_purchased_storage_allocation is enabled' do
      stub_application_setting(automatic_purchased_storage_allocation: true)

      expect(model.enforce_limit?).to eq(true)
    end

    it 'returns false if automatic_purchased_storage_allocation is disabled' do
      stub_application_setting(automatic_purchased_storage_allocation: false)

      expect(model.enforce_limit?).to eq(false)
    end
  end

  describe '#enforcement_type' do
    it 'returns :project_repository_limit' do
      expect(model.enforcement_type).to eq(:project_repository_limit)
    end
  end
end
