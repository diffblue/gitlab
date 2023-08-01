# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Progress, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item, :objective) }
  let_it_be_with_reload(:progress) { create(:progress, work_item: work_item, progress: 20) }
  let(:work_item_1) { create(:work_item, :objective) }

  shared_examples 'a progress widget attribute' do |attribute|
    subject { described_class.new(work_item).send(attribute) }

    it { is_expected.to eq(work_item.progress.send(attribute)) }

    context 'when progress object is not present for work item' do
      it 'returns nil' do
        expect(described_class.new(work_item_1).send(attribute)).to be(nil)
      end
    end
  end

  describe '#progress' do
    it_behaves_like 'a progress widget attribute', :progress
  end

  describe '#updated_at' do
    it_behaves_like 'a progress widget attribute', :updated_at
  end

  describe '#start_value' do
    it_behaves_like 'a progress widget attribute', :start_value
  end

  describe '#current_value' do
    it_behaves_like 'a progress widget attribute', :current_value
  end

  describe '#end_value' do
    it_behaves_like 'a progress widget attribute', :end_value
  end
end
