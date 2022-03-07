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

    describe 'cadence_is_automatic' do
      context 'when creating a new cadence' do
        it 'does not allow the creation of manul cadences' do
          cadence = build(:iterations_cadence, automatic: false).tap { |cadence| cadence.valid? }

          expect(cadence.errors.full_messages).to include(_('Manual iteration cadences are deprecated. Only automatic iteration cadences are allowed.'))
        end
      end

      context 'when cadence already existed as manual' do
        let_it_be(:manual_cadence, refind: true) { build(:iterations_cadence).tap { |cadence| cadence.save!(validate: false) } }

        context 'when `automatic` is not updated' do
          it 'allows to change other attributes' do
            manual_cadence.assign_attributes(duration_in_weeks: 2, iterations_in_advance: 4)

            expect(manual_cadence).to be_valid
          end
        end
      end

      context 'when cadence already existed as automatic' do
        let_it_be(:automatic_cadence, refind: true) { create(:iterations_cadence) }

        context 'when changing a cadence to manual' do
          it 'adds a validation error' do
            automatic_cadence.assign_attributes(duration_in_weeks: 2, iterations_in_advance: 4, automatic: false)

            expect(automatic_cadence).to be_invalid
            expect(automatic_cadence.errors.full_messages).to include(_('Manual iteration cadences are deprecated. Only automatic iteration cadences are allowed.'))
          end
        end
      end
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
