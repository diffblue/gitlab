# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::Aggregation, type: :model, feature_category: :value_stream_management do
  subject(:model) { build(:value_stream_dashboard_aggregation) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).optional(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_inclusion_of(:enabled).in_array([true, false]) }
  end

  describe '.load_batch' do
    let_it_be(:aggregation1) { create(:value_stream_dashboard_aggregation, last_run_at: nil) }
    let_it_be(:aggregation2) { create(:value_stream_dashboard_aggregation, last_run_at: 2.months.ago) }
    let_it_be(:aggregation3) { create(:value_stream_dashboard_aggregation, last_run_at: nil) }
    let_it_be(:aggregation4) { create(:value_stream_dashboard_aggregation, last_run_at: 3.months.ago) }

    delegate :load_batch, to: described_class

    context 'when the cursor is empty' do
      it 'returns the records with the oldest or empty last_run_at values' do
        expect(load_batch).to eq([aggregation1, aggregation3, aggregation4, aggregation2])
      end

      context 'when bath size is given' do
        it { expect(load_batch({}, 2)).to eq([aggregation1, aggregation3]) }
      end
    end

    context 'when top_level_namespace_id is present in the cursor' do
      it 'returns the aggregation record associated with the top_level_namespace_id as the first record' do
        expect(load_batch({ top_level_namespace_id: aggregation3.id })).to eq([aggregation3, aggregation1,
          aggregation4, aggregation2])
      end

      context 'when top_level_namespace_id no longer exists' do
        it 'ignores the given top_level_namespace_id' do
          expect(load_batch({ top_level_namespace_id: non_existing_record_id })).to eq([
            aggregation1,
            aggregation3,
            aggregation4,
            aggregation2
          ])
        end
      end

      context 'when a cursor is a Gitlab::Analytics::ValueStreamDashboard::NamespaceCursor' do
        it 'returns correct data' do
          cursor = Analytics::ValueStreamDashboard::TopLevelGroupCounterService
            .load_cursor(raw_cursor: { top_level_namespace_id: aggregation3.id })

          expect(load_batch(cursor)).to eq([aggregation3, aggregation1,
            aggregation4, aggregation2])
        end
      end
    end
  end
end
