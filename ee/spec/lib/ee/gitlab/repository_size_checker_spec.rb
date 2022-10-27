# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositorySizeChecker do
  let(:current_size) { 0 }
  let(:limit) { 50 }
  let(:namespace) { build(:namespace, additional_purchased_storage_size: additional_purchased_storage) }
  let(:total_repository_size_excess) { 0 }
  let(:additional_purchased_storage) { 0 }
  let(:enabled) { true }
  let(:automatic_purchased_storage_allocation) { true }

  subject do
    described_class.new(
      current_size_proc: -> { current_size.megabytes },
      limit: limit.megabytes,
      namespace: namespace,
      enabled: enabled
    )
  end

  before do
    stub_application_setting(automatic_purchased_storage_allocation: automatic_purchased_storage_allocation)

    if namespace
      allow(namespace).to receive(:total_repository_size_excess)
        .and_return(total_repository_size_excess.megabytes)
    end
  end

  describe '#above_size_limit?' do
    shared_examples 'original logic (additional storage not considered)' do
      include_examples 'checker size above limit'
      include_examples 'checker size not over limit'

      context 'when over the default limit but would be under the limit if additional storage was enabled' do
        let(:current_size) { 100 }
        let(:additional_purchased_storage) { 60 }

        it 'returns true' do
          expect(subject.above_size_limit?).to eq(true)
        end
      end
    end

    context 'when enabled is false' do
      let(:enabled) { false }

      context 'when size is under the limit' do
        it 'returns false' do
          expect(subject.above_size_limit?).to eq(false)
        end
      end

      context 'when size is above the limit' do
        let(:current_size) { 100 }

        it 'returns false' do
          expect(subject.above_size_limit?).to eq(false)
        end
      end
    end

    context 'when automatic_purchased_storage_allocation is false' do
      let(:automatic_purchased_storage_allocation) { false }

      include_examples 'original logic (additional storage not considered)'
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      include_examples 'original logic (additional storage not considered)'
    end

    context 'when there are no locked projects (total repository excess < additional storage)' do
      let(:current_size) { 100 } # current_size > limit
      let(:total_repository_size_excess) { 5 }
      let(:additional_purchased_storage) { 10 }

      it 'returns false' do
        expect(subject.above_size_limit?).to eq(false)
      end
    end

    context 'when there are no locked projects (total repository excess == additional storage)' do
      let(:current_size) { 100 } # current_size > limit
      let(:total_repository_size_excess) { 10 }
      let(:additional_purchased_storage) { 10 }

      it 'returns false' do
        expect(subject.above_size_limit?).to eq(false)
      end
    end

    context 'when there are locked projects (total repository excess > additional storage)' do
      let(:total_repository_size_excess) { 12 }
      let(:additional_purchased_storage) { 10 }

      include_examples 'checker size above limit'
      include_examples 'checker size not over limit'
    end
  end

  describe '#exceeded_size' do
    include_examples 'checker size exceeded'

    context 'when automatic_purchased_storage_allocation is false' do
      let(:automatic_purchased_storage_allocation) { false }

      include_examples 'checker size exceeded'
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      include_examples 'checker size exceeded'
    end

    context 'with additional purchased storage' do
      let(:total_repository_size_excess) { 10 }
      let(:additional_purchased_storage) { 10 }

      context 'when no change size provided' do
        context 'when current size + total repository size excess is below the limit (additional purchase storage not used)' do
          let(:current_size) { limit - 1 }

          it 'returns zero' do
            expect(subject.exceeded_size).to eq(0)
          end
        end

        context 'when current size + total repository size excess is equal to the limit (additional purchase storage not used)' do
          let(:current_size) { limit }

          it 'returns zero' do
            expect(subject.exceeded_size).to eq(0)
          end
        end

        context 'when there is remaining additional purchased storage (current size + other project excess use some additional purchased storage)' do
          let(:current_size) { limit + 1 }

          it 'returns zero' do
            expect(subject.exceeded_size).to eq(0)
          end
        end

        context 'when additional purchased storage is depleted (current size + other project excess exceed additional purchased storage)' do
          let(:total_repository_size_excess) { 15 }
          let(:current_size) { 61 }

          it 'returns a positive number' do
            expect(subject.exceeded_size).to eq(5.megabytes)
          end
        end
      end

      context 'when a change size is provided' do
        let(:change_size) { 1.megabyte }

        context 'when current size + total repository size excess is below the limit (additional purchase storage not used)' do
          let(:current_size) { limit - 1 }

          it 'returns zero' do
            expect(subject.exceeded_size(change_size)).to eq(0)
          end
        end

        context 'when current size + total repository size excess is equal to the limit (additional purchase storage depleted)' do
          let(:current_size) { limit }

          it 'returns a positive number' do
            expect(subject.exceeded_size(change_size)).to eq(1.megabyte)
          end
        end
      end
    end

    context 'without additional purchased storage' do
      context 'when namespace has total_repository_size_excess but project is below limit' do
        let(:total_repository_size_excess) { 50 }
        let(:change_size) { 1.megabyte }
        let(:limit) { 10 }
        let(:current_size) { 5 }

        it 'returns zero' do
          expect(subject.exceeded_size(change_size)).to eq(0)
        end
      end

      include_examples 'checker size exceeded'
    end
  end

  describe '#additional_repo_storage_available?' do
    it 'returns true when automatic_purchased_storage_allocation is true' do
      expect(subject.additional_repo_storage_available?).to eq(true)
    end

    it 'returns false when automatic_purchased_storage_allocation is false' do
      stub_application_setting(automatic_purchased_storage_allocation: false)

      expect(subject.additional_repo_storage_available?).to eq(false)
    end
  end
end
