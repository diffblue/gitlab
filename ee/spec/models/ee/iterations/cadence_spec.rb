# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Iterations::Cadence, :freeze_time do
  describe 'associations' do
    subject { build(:iterations_cadence) }

    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:iterations).inverse_of(:iterations_cadence) }
  end

  describe 'validations' do
    using RSpec::Parameterized::TableSyntax

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

    shared_examples 'updating the start date is valid' do
      where(:prev_start_date, :new_start_date) do
        Date.current + 1.day  | Date.current
        Date.current + 7.days | Date.current + 3.days
        Date.current + 7.days | Date.current + 14.days
      end

      with_them do
        it 'is valid' do
          cadence = build(:iterations_cadence, start_date: prev_start_date, automatic: automatic).tap { |cadence| cadence.save!(validate: false) }
          cadence.assign_attributes({ start_date: new_start_date })

          expect(cadence).to be_valid
        end
      end
    end

    describe 'start date validation' do
      let_it_be(:group) { create(:group) }

      let(:cadence) { create(:iterations_cadence, group: group, start_date: Date.current, duration_in_weeks: 1) }

      shared_examples 'an error is raised when start date is invalid' do
        it 'raises an error' do
          cadence.start_date = new_start_date

          expect(cadence).to be_invalid
          expect(cadence.errors.full_messages).to include(error_message)
        end
      end

      context 'when cadence has a current iteration' do
        let!(:current_iteration) { create(:iteration, iterations_cadence: cadence, start_date: Date.current) }

        context 'when a new start date overlaps with the current iteration' do
          let(:new_start_date) { Date.current + 1 }
          let(:error_message) { "The automation start date must come after the active iteration #{current_iteration.period}." }

          it_behaves_like 'an error is raised when start date is invalid'
        end
      end

      context 'when cadence has a past iteration' do
        let!(:past_iteration) { create(:iteration, iterations_cadence: cadence, start_date: Date.current - 1.week, due_date: Date.current - 1.day) }

        context 'when the new start date overlaps with the past iteration' do
          let(:new_start_date) { Date.current - 1.week }
          let(:error_message) { "The automation start date must come after the past iteration #{past_iteration.period}." }

          it_behaves_like 'an error is raised when start date is invalid'
        end

        it 'does not raise an error when start date does not overlap with the past iteration' do
          cadence.start_date = Date.current

          expect(cadence).to be_valid
        end
      end

      context 'when a past iteration would be retroactively created' do
        let(:earliest_possible_start_date) { Date.current - 1.week + 1.day }

        where(:start_date) do
          [
            [lazy { earliest_possible_start_date - 1.day }],
            [lazy { earliest_possible_start_date - 2.days }]
          ]
        end

        with_them do
          it 'raises an error' do
            cadence = build(:iterations_cadence, group: group, start_date: start_date, duration_in_weeks: 1)
            error_msg = "The automation start date would retroactively create a past iteration. #{earliest_possible_start_date} is the earliest possible start date."

            expect(cadence).to be_invalid
            expect(cadence.errors.full_messages).to include(error_msg)
          end
        end
      end
    end
  end

  describe 'callbacks' do
    let_it_be(:group) { create(:group) }

    context 'before_validation :reset_automation_params' do
      let(:cadence) { create(:iterations_cadence, group: group, iterations_in_advance: 1, duration_in_weeks: 1, roll_over: true) }

      context 'when converted to manual' do
        it 'resets automation params', :aggregate_failures do
          cadence.update!(automatic: false)

          expect(cadence.iterations_in_advance).to eq(nil)
          expect(cadence.duration_in_weeks).to eq(nil)
          expect(cadence.roll_over).to eq(false)
        end
      end
    end

    context 'after_commit' do
      context 'ensure_iterations_in_advance' do
        let(:cadence) { create(:iterations_cadence, group: group) }

        it 'does not call CreateIterationsWorker when non-automation field is updated' do
          cadence

          expect(::Iterations::Cadences::CreateIterationsWorker).not_to receive(:perform_async)

          cadence.update!({ title: "foobar" })
        end

        it 'does not call CreateIterationsWorker when manual cadence is created' do
          expect(::Iterations::Cadences::CreateIterationsWorker).not_to receive(:perform_async)

          build(:iterations_cadence, group: group, automatic: false).tap { |cadence| cadence.save!(validate: false) }
        end

        [
          { start_date: Date.current }, { duration_in_weeks: 2 }, { iterations_in_advance: 3 }
        ].each do |updated_attrs|
          it 'calls CreateIterationsWorker when automation fields are updated' do
            cadence

            expect(::Iterations::Cadences::CreateIterationsWorker).to receive(:perform_async).with(cadence.id)

            cadence.update!(updated_attrs)
          end

          it 'calls CreateIterationsWorker when automatic cadence is created' do
            expect(::Iterations::Cadences::CreateIterationsWorker).to receive(:perform_async)

            build(:iterations_cadence, group: group, **updated_attrs).save!
          end
        end
      end
    end
  end

  describe 'scopes' do
    describe 'next_to_auto_schedule' do
      let_it_be(:current_date) { Time.zone.now.to_date }
      let_it_be(:group) { create(:group) }
      let_it_be(:cadence1) { create(:iterations_cadence, group: group, next_run_date: current_date) }
      let_it_be(:cadence2) { create(:iterations_cadence, group: group, next_run_date: current_date - 1.day) }
      let_it_be(:cadence3) { create(:iterations_cadence, group: group, next_run_date: nil) } # a newly created cadence would have nil as next_run_date.
      let_it_be(:cadence4) { create(:iterations_cadence, group: group, next_run_date: current_date + 1.day) }
      let_it_be(:manual_cadence) { build(:iterations_cadence, group: group, automatic: false).tap { |cadence| cadence.save!(validate: false) } }

      it "returns automatic cadences with 'next_run_date' set in the past or to the current date" do
        expect(described_class.next_to_auto_schedule).to match_array([cadence1, cadence2, cadence3])
      end
    end
  end

  describe '#next_schedule_date_and_count' do
    let_it_be(:group) { create(:group) }

    let(:cadence_start_date) { Date.new(2022, 4, 1) }
    let(:cadence_start_day) { Date::DAYS_INTO_WEEK.key(cadence_start_date.wday) }
    let(:cadence) { build(:iterations_cadence, group: group, start_date: cadence_start_date, iterations_in_advance: 1, duration_in_weeks: 1).tap { |cadence| cadence.save!(validate: false) } }
    let(:schedule_start_date) { cadence.next_schedule_date_and_count[0] }
    let(:schedule_count) { cadence.next_schedule_date_and_count[1] }

    where(:today, :existing_iterations, :expected_schedule_start, :expected_schedule_count) do
      [
        [
          lazy { cadence_start_date + 6.days },
          [],
          lazy { cadence_start_date },
          1 + 1 # 1 current iteration + 1 future iteration
        ],
        [
          lazy { cadence_start_date },
          [],
          lazy { cadence_start_date },
          1 + 1 # 1 current iteration + 1 future iteration
        ],
        [
          lazy { cadence_start_date - 6.days },
          [],
          lazy { cadence_start_date },
          1 # 1 future iteration
        ],
        [
          lazy { cadence_start_date + 7.days },
          lazy { [{ start_date: cadence_start_date, due_date: cadence_start_date + 6.days }] },
          lazy { cadence_start_date + 7.days },
          1 + 1 # 1 current iteration + 1 future iteration
        ],
        [
          # There cannot be a current iteration scheduled in this scenario.
          # The past and only iteration ended on Sat Apr 9th and the next Friday comes on Apr 15th.
          # We would encounter this type of edge case if the cadence had been previously manually managed but has been converted to automatic.
          Date.new(2022, 4, 10),
          [{ start_date: Date.new(2022, 4, 5), due_date: Date.new(2022, 4, 9) }],
          lazy { Date.new(2022, 4, 9).next_week.next_occurring(cadence_start_day) },
          1 # 1 future iteration
        ],
        [
          Date.new(2022, 4, 10),
          lazy do
            [
              { start_date: Date.new(2022, 4, 1), due_date: Date.new(2022, 4, 4) },
              { start_date: Date.new(2022, 4, 5), due_date: Date.new(2022, 4, 10) }
            ]
          end,
          lazy { Date.new(2022, 4, 10).next_week.next_occurring(cadence_start_day) },
          1 # 1 future iteration
        ]
      ]
    end

    with_them do
      before do
        travel_to today

        existing_iterations.each do |i|
          create(:iteration, iterations_cadence: cadence, start_date: i[:start_date], due_date: i[:due_date])
        end
      end

      it 'returns the next occurring cadence start day after the most recent iteration is due with correct scheduling count' do
        expect(schedule_start_date.wday).to eq(expected_schedule_start.wday)
        expect(schedule_start_date).to eq(expected_schedule_start)
        expect(schedule_count).to eq(expected_schedule_count)
      end
    end
  end

  describe '#next_open_iteration_start_date' do
    let_it_be(:group) { create(:group) }

    let(:today) { Date.new(2022, 4, 1) }
    let(:cadence_start_date) { Date.new(2022, 3, 1) }
    let(:cadence_start_day) { Date::DAYS_INTO_WEEK.key(cadence_start_date.wday) }

    let(:cadence) { build(:iterations_cadence, group: group, start_date: cadence_start_date, iterations_in_advance: 1, duration_in_weeks: 1).tap { |cadence| cadence.save!(validate: false) } }

    before do
      travel_to today
    end

    it 'returns the cadence start date when neither past nor current iteration exists' do
      expect(cadence.next_open_iteration_start_date).to eq(cadence.start_date)
    end

    context 'when start date is set to an upcoming date' do
      let(:cadence_start_date) { today + 1 }

      it 'returns the cadence start date' do
        expect(cadence.next_open_iteration_start_date).to eq(cadence.start_date)
      end
    end

    context 'when past iteration exists' do
      let!(:past_iteration) { create(:iteration, iterations_cadence: cadence, start_date: cadence_start_date, due_date: today - 7.days ) }

      context 'when past iteration is the cadence start day from the previous week' do
        it "returns the cadence start day for the current week" do
          expect(cadence.next_open_iteration_start_date.wday).to eq(cadence.start_date.wday)
          expect(cadence.next_open_iteration_start_date).to eq(today.beginning_of_week.next_occurring(cadence_start_day))
        end
      end

      context 'when many iterations can fit in-between the current date and the previous iteration due date' do
        let!(:past_iteration) { create(:iteration, iterations_cadence: cadence, start_date: cadence_start_date, due_date: cadence_start_date + 1.day ) }

        it "returns the date for the cadence start day nearest to the current date from the last iteration's due date" do
          expect(cadence.next_open_iteration_start_date.wday).to eq(cadence.start_date.wday)
          expect(cadence.next_open_iteration_start_date).to eq(today.prev_occurring(cadence_start_day))
        end
      end

      context 'when past iteration is yesterday' do
        let!(:past_iteration) { create(:iteration, iterations_cadence: cadence, start_date: cadence_start_date, due_date: today - 1.day ) }

        it "returns the date for the cadence start day nearest to the current date from the last iteration's due date" do
          expect(cadence.next_open_iteration_start_date.wday).to eq(cadence.start_date.wday)
          expect(cadence.next_open_iteration_start_date).to eq(past_iteration.due_date.next_occurring(cadence_start_day))
        end
      end

      context 'when current iteration exists' do
        let!(:current_iteration) { create(:iteration, iterations_cadence: cadence, start_date: today) }

        it "returns the date for the cadence start day following the current iteration's due date" do
          expect(cadence.next_open_iteration_start_date.wday).to eq(cadence.start_date.wday)
          expect(cadence.next_open_iteration_start_date).to eq(current_iteration.due_date.next_occurring(cadence_start_day))
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
        Date.current     | lazy { %w[iteration a b] }
        2.weeks.from_now | lazy { %w[a iteration b] }
        4.weeks.from_now | lazy { %w[a b iteration] }
      end

      with_them do
        before do
          Iteration.insert_all!(
            [
              {
                sequence: nil,
                title: 'iteration',
                start_date: start_date,
                due_date: start_date + 4.days,
                iterations_cadence_id: iterations_cadence.id,
                iid: 1,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              },
              {
                sequence: nil,
                title: 'a',
                start_date: 1.week.from_now,
                due_date: 1.week.from_now + 4.days,
                iterations_cadence_id: iterations_cadence.id,
                iid: 2,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              },
              {
                sequence: nil,
                title: 'b',
                start_date: 3.weeks.from_now,
                due_date: 3.weeks.from_now + 4.days,
                iterations_cadence_id: iterations_cadence.id,
                iid: 3,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              }
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
