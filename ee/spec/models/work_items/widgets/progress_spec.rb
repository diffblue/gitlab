# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Progress, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item, :objective) }
  let_it_be_with_reload(:progress) { create(:progress, work_item: work_item, progress: 20) }
  let(:work_item_1) { create(:work_item, :objective) }

  describe '#progress' do
    subject { described_class.new(work_item).progress }

    it { is_expected.to eq(work_item.progress.progress) }

    context 'when progress object is not present for work item' do
      it 'returns nil' do
        expect(described_class.new(work_item_1).progress).to be(nil)
      end
    end
  end

  describe '#updated_at' do
    subject { described_class.new(work_item).updated_at }

    it { is_expected.to eq(work_item.progress.updated_at) }

    context 'when progress object is not present for work item' do
      it 'returns nil' do
        expect(described_class.new(work_item_1).updated_at).to be(nil)
      end
    end
  end
end
