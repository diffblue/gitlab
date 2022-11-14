# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceLimit do
  let(:namespace_limit) { build(:namespace_limit) }
  let(:usage_ratio) { 0.5 }
  let(:namespace_storage_limit_enabled) { true }

  subject { namespace_limit }

  before do
    stub_feature_flags(namespace_storage_limit: namespace_storage_limit_enabled)

    [Namespaces::Storage::RootSize, Namespaces::Storage::RootExcessSize].each do |class_name|
      allow_next_instance_of(class_name, namespace_limit.namespace) do |root_storage|
        allow(root_storage).to receive(:usage_ratio).and_return(usage_ratio)
      end
    end
  end

  it { is_expected.to belong_to(:namespace) }

  describe '#temporary_storage_increase_enabled?' do
    subject { namespace_limit.temporary_storage_increase_enabled? }

    context 'when date is not set' do
      it { is_expected.to eq(false) }
    end

    context 'when temporary storage increase end date is today' do
      before do
        namespace_limit.temporary_storage_increase_ends_on = Date.today
      end

      it { is_expected.to eq(true) }

      context 'when feature is disabled' do
        before do
          stub_feature_flags(temporary_storage_increase: false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when temporary storage increase end date is exceeded' do
      before do
        namespace_limit.temporary_storage_increase_ends_on = Date.today - 1.day
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#eligible_for_temporary_storage_increase?' do
    subject { namespace_limit.eligible_for_temporary_storage_increase? }

    context 'when usage ratio is above the threshold' do
      let(:usage_ratio) { 0.5 }

      it { is_expected.to eq(true) }

      context 'when feature flag :temporary_storage_increase disabled' do
        before do
          stub_feature_flags(temporary_storage_increase: false)
        end

        context 'when feature flag :namespace_storage_limit disabled' do
          let(:namespace_storage_limit_enabled) { false }

          it { is_expected.to eq(false) }
        end

        it { is_expected.to eq(false) }
      end

      context 'when feature flag :namespace_storage_limit disabled' do
        let(:namespace_storage_limit_enabled) { false }

        it { is_expected.to eq(true) }
      end
    end

    context 'when usage ratio is below the threshold' do
      let(:usage_ratio) { 0.49 }

      context 'when feature flag :namespace_storage_limit disabled' do
        let(:namespace_storage_limit_enabled) { false }

        it { is_expected.to eq(false) }
      end

      it { is_expected.to eq(false) }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }

    context 'with namespace_is_root_namespace' do
      let(:namespace_limit) { build(:namespace_limit, namespace: namespace) }

      context 'when associated namespace is root' do
        let(:namespace) { build(:group, parent: nil) }

        it { is_expected.to be_valid }
      end

      context 'when associated namespace is not root' do
        let(:namespace) { build(:group, :nested) }

        it 'is invalid' do
          expect(subject).to be_invalid
          expect(subject.errors[:namespace]).to include('must be a root namespace')
        end
      end
    end

    context 'with temporary_storage_increase_set_once' do
      context 'when temporary_storage_increase_ends_on was nil' do
        it 'can be set' do
          namespace_limit.temporary_storage_increase_ends_on = Date.today

          expect(namespace_limit).to be_valid
        end
      end

      context 'when temporary_storage_increase_ends_on is already set' do
        before do
          namespace_limit.update_attribute(:temporary_storage_increase_ends_on, 30.days.ago)
        end

        it 'can not be set again' do
          namespace_limit.temporary_storage_increase_ends_on = Date.today

          expect(subject).to be_invalid
          expect(subject.errors[:temporary_storage_increase_ends_on]).to include('can only be set once')
        end
      end
    end

    context 'with temporary_storage_increase_eligibility' do
      before do
        namespace_limit.temporary_storage_increase_ends_on = Date.today
      end

      context 'when storage usage is above threshold' do
        let(:usage_ratio) { 0.5 }

        it { is_expected.to be_valid }

        context 'when feature flag :namespace_storage_limit disabled' do
          let(:namespace_storage_limit_enabled) { false }

          it { is_expected.to be_valid }
        end
      end

      context 'when storage usage is below threshold' do
        let(:usage_ratio) { 0.49 }

        it 'is invalid' do
          expect(namespace_limit).to be_invalid
          expect(namespace_limit.errors[:temporary_storage_increase_ends_on])
            .to include("can only be set with more than 50% usage")
        end

        context 'when feature flag :namespace_storage_limit disabled' do
          let(:namespace_storage_limit_enabled) { false }

          it 'is invalid' do
            expect(namespace_limit).to be_invalid
            expect(namespace_limit.errors[:temporary_storage_increase_ends_on])
              .to include("can only be set with more than 50% usage")
          end
        end
      end
    end
  end
end
