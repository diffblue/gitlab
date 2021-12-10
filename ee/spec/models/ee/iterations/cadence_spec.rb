# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Iterations::Cadence do
  describe 'associations' do
    subject { build(:iterations_cadence) }

    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:iterations).inverse_of(:iterations_cadence) }
  end

  describe 'validations' do
    let(:instance_attributes) { {} }

    subject { build(:iterations_cadence, **instance_attributes) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:group_id) }
    it { is_expected.not_to allow_value(nil).for(:active) }
    it { is_expected.not_to allow_value(nil).for(:automatic) }
    it { is_expected.to validate_length_of(:description).is_at_most(5000) }

    context 'when iteration cadence is automatic' do
      let(:instance_attributes) { { automatic: true } }

      it { is_expected.to validate_presence_of(:start_date) }
    end

    context 'when iteration cadence is manual' do
      let(:instance_attributes) { { automatic: false } }

      it { is_expected.not_to validate_presence_of(:start_date) }
    end
  end

  describe '#update_iteration_sequences', :aggregate_failures do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group) }
    let_it_be(:iterations_cadence) { create(:iterations_cadence, group: group) }

    let(:expected_sequence) { (1..iterations_cadence.iterations.size).to_a }
    let(:ordered_iterations) { iterations_cadence.iterations.order(:start_date) }

    context 'an iteration is created or updated' do
      where(:start_date, :expected_ordered_title) do
        1.week.ago       | lazy { %w[iteration a b] }
        Date.today       | lazy { %w[iteration a b] }
        2.weeks.from_now | lazy { %w[a iteration b] }
        4.weeks.from_now | lazy { %w[a b iteration] }
      end

      with_them do
        before do
          Iteration.insert_all!([
            {  sequence: nil, title: 'iteration', start_date: start_date, due_date: start_date + 4.days, iterations_cadence_id: iterations_cadence.id, iid: 1, created_at: Time.zone.now, updated_at: Time.zone.now },
            {  sequence: nil, title: 'a', start_date: 1.week.from_now, due_date: 1.week.from_now + 4.days, iterations_cadence_id: iterations_cadence.id, iid: 2, created_at: Time.zone.now, updated_at: Time.zone.now },
            {  sequence: nil, title: 'b', start_date: 3.weeks.from_now, due_date: 3.weeks.from_now + 4.days, iterations_cadence_id: iterations_cadence.id, iid: 3, created_at: Time.zone.now, updated_at: Time.zone.now }
          ])
        end

        it 'sequence numbers are correctly updated' do
          iterations_cadence.update_iteration_sequences

          expect(ordered_iterations.map(&:sequence)).to eq(expected_sequence)
          expect(ordered_iterations.map(&:title)).to eq(expected_ordered_title)
        end
      end
    end
  end
end
