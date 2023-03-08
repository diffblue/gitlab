# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::CreateIterationsInAdvanceService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:manual_cadence) { build(:iterations_cadence, group: group, active: true, automatic: false, start_date: 2.weeks.ago).tap { |cadence| cadence.save!(validate: false) } }

  let(:sequences) { (1..cadence.iterations.size).to_a }
  let(:ordered_iterations) { cadence.iterations.order(:start_date) }
  let(:ordered_sequences) { ordered_iterations.map(&:sequence) }
  let(:ordered_dates) { ordered_iterations.map { |i| [i.start_date, i.due_date] } }
  let(:ordered_states) { ordered_iterations.map(&:state) }
  let(:expected_next_run_date) { cadence.iterations.with_start_date_after(today).last(cadence.iterations_in_advance).first.start_date }
  let(:expected_states) { expected_iterations.map { |i| i[:state] } }

  subject { described_class.new(user, cadence).execute }

  describe '#execute' do
    context 'when user has permissions to create iterations' do
      context 'when user is a group developer' do
        before do
          group.add_developer(user)
        end

        context 'with nil cadence' do
          let(:cadence) { nil }

          it 'returns error' do
            expect(subject).to be_error
          end
        end

        context 'with manual cadence' do
          let(:cadence) { manual_cadence }

          it 'returns error' do
            expect(subject).to be_error
          end

          context 'when cadence is converted to use automatic scheduling', :freeze_time do
            let(:today) { Date.new(2022, 4, 1) }
            let(:cadence) { build(:iterations_cadence, group: group, automatic: false, **cadence_params).tap { |cadence| cadence.save!(validate: false) } }

            shared_examples 'manual cadence is updated' do
              before do
                travel_to today

                # Populate existing, manually created iterations
                existing_iterations.each do |i|
                  create(:iteration, iterations_cadence: cadence, start_date: i[:start_date], due_date: i[:due_date])
                end

                cadence.update!(automatic: true)

                subject
              end

              it 'manages and schedules iterations without modifying past and current iterations', :aggregate_failures do
                expect(ordered_sequences).to eq(sequences)
                expect(ordered_states).to eq(expected_states)
                expect(ordered_dates).to eq(expected_iterations.map { |i| [i[:start_date], i[:due_date]] })
                expect(cadence.next_run_date).to eq(expected_next_run_date)
              end
            end

            context 'when past iteration exists and automation start date is set to today' do
              let(:cadence_params) { { start_date: today, iterations_in_advance: 2, duration_in_weeks: 1 } }
              let(:existing_iterations) { [{ start_date: Date.new(2022, 3, 25), due_date: Date.new(2022, 3, 31) }] }
              let(:expected_iterations) do
                [
                  { **existing_iterations[0], state: 'closed' },
                  { start_date: today, due_date: today + 1.week - 1, state: 'current' },
                  { start_date: today + 1.week, due_date: today + 2.weeks - 1, state: 'upcoming' },
                  { start_date: today + 2.weeks, due_date: today + 3.weeks - 1, state: 'upcoming' }
                ]
              end

              it_behaves_like 'manual cadence is updated'
            end

            context 'when current iteration exists and automation start date is set to an upcoming date' do
              let(:upcoming_date) { Date.new(2022, 4, 4) }
              let(:cadence_params) { { start_date: upcoming_date, iterations_in_advance: 2, duration_in_weeks: 1 } }
              let(:existing_iterations) { [{ start_date: Date.new(2022, 3, 28), due_date: today }] }
              let(:expected_iterations) do
                [
                  { **existing_iterations[0], state: 'current' },
                  { start_date: upcoming_date, due_date: upcoming_date + 1.week - 1, state: 'upcoming' },
                  { start_date: upcoming_date + 1.week, due_date: upcoming_date + 2.weeks - 1, state: 'upcoming' }
                ]
              end

              it_behaves_like 'manual cadence is updated'
            end

            context 'when upcoming iteration exists and automation start date is set to an upcoming date' do
              let(:upcoming_date) { Date.new(2022, 8, 4) }
              let(:cadence_params) { { start_date: upcoming_date, iterations_in_advance: 2, duration_in_weeks: 4 } }
              let(:existing_iterations) do
                [
                  { start_date: upcoming_date, due_date: upcoming_date + 1.day },
                  { start_date: Date.new(2022, 8, 11), due_date: Date.new(2022, 8, 11) + 1.day }
                ]
              end

              let(:expected_iterations) do
                [
                  { start_date: upcoming_date, due_date: upcoming_date + 4.weeks - 1, state: 'upcoming' },
                  { start_date: upcoming_date + 4.weeks, due_date: upcoming_date + 8.weeks - 1, state: 'upcoming' }
                ]
              end

              it_behaves_like 'manual cadence is updated'
            end

            context 'when current and upcoming iteration exists and automation start date is set to an upcoming date' do
              let(:upcoming_date) { Date.new(2022, 4, 4).next_occurring(:friday) }
              let(:cadence_params) { { start_date: upcoming_date, iterations_in_advance: 4, duration_in_weeks: 3 } }
              let(:existing_iterations) do
                [
                  { start_date: Date.new(2022, 4, 1), due_date: Date.new(2022, 4, 4) },
                  { start_date: Date.new(2022, 4, 5), due_date: Date.new(2022, 4, 6) }
                ]
              end

              let(:expected_iterations) do
                [
                  { **existing_iterations[0], state: 'current' },
                  { start_date: upcoming_date, due_date: upcoming_date + 3.weeks - 1, state: 'upcoming' },
                  { start_date: upcoming_date + 3.weeks, due_date: upcoming_date + 6.weeks - 1, state: 'upcoming' },
                  { start_date: upcoming_date + 6.weeks, due_date: upcoming_date + 9.weeks - 1, state: 'upcoming' },
                  { start_date: upcoming_date + 9.weeks, due_date: upcoming_date + 12.weeks - 1, state: 'upcoming' }
                ]
              end

              it_behaves_like 'manual cadence is updated'
            end

            context 'when past and future iteration exists and automation start date is set to today' do
              let(:cadence_params) { { start_date: today, iterations_in_advance: 2, duration_in_weeks: 3 } }
              let(:first_friday_2021) { Date.new(2021).next_occurring(:friday) }
              let(:first_monday_2022) { Date.new(2022).next_occurring(:monday) }
              let(:existing_iterations) do
                [
                  { start_date: first_friday_2021, due_date: first_friday_2021.next_occurring(:saturday) },
                  { start_date: first_monday_2022, due_date: first_monday_2022.next_occurring(:wednesday) },
                  { start_date: Date.new(2022, 4, 2), due_date: Date.new(2022, 4, 3) },
                  { start_date: Date.new(2022, 4, 5), due_date: Date.new(2022, 4, 10) }
                ]
              end

              let(:expected_iterations) do
                [
                  { **existing_iterations[0], state: 'closed' },
                  { **existing_iterations[1], state: 'closed' },
                  { start_date: today, due_date: today + 3.weeks - 1, state: 'current' },
                  { start_date: today + 3.weeks, due_date: today + 6.weeks - 1, state: 'upcoming' },
                  { start_date: today + 6.weeks, due_date: today + 9.weeks - 1, state: 'upcoming' }
                ]
              end

              it_behaves_like 'manual cadence is updated'
            end
          end
        end

        context 'with inactive cadence' do
          let(:cadence) { create(:iterations_cadence, group: group, active: false, automatic: true) }

          it 'returns error' do
            expect(subject).to be_error
          end
        end

        context 'with automatic and active cadence' do
          let(:cadence) { create(:iterations_cadence, group: group, **initial_cadence_params) }

          shared_examples 'iterations are scheduled' do
            let(:days_of_week) { ordered_iterations.map { |i| i.start_date.wday }.uniq }
            let(:expected_dates) { expected_iterations.map { |i| [i[:start_date], i[:start_date] + i[:duration] - 1] } }

            it 'correctly manages and schedules iterations', :aggregate_failures do
              # Sanity check: ensure that all iterations start on the same day of the week and have correct sequences
              expect(ordered_sequences).to eq(sequences)
              expect(days_of_week.one?).to be(true)
              expect(days_of_week.first).to be(cadence.start_date.wday)

              expect(ordered_dates).to eq(expected_dates)
              expect(cadence.next_run_date).to eq(expected_next_run_date)
            end
          end

          shared_examples 'iterations are scheduled on an initial run' do
            let(:today) { initial_schedule_date }
            let(:expected_iterations) { expected_initial_iterations }

            before do
              travel_to today
              subject
            end

            it_behaves_like 'iterations are scheduled'

            it 'schedule iterations with correct states' do
              expect(ordered_states).to eq(expected_states)
            end
          end

          shared_examples 'iterations are scheduled on a subsequent run' do
            let(:today) { next_schedule_date }
            let(:expected_iterations) { expected_final_iterations }

            before do
              travel_to initial_schedule_date
              subject

              travel_to today
              cadence.update!(**cadence_params)
              described_class.new(user, cadence.reload).execute
            end

            it_behaves_like 'iterations are scheduled'
          end

          context 'when cadence starts on a past date' do
            context 'when the cadence start date was a day ago' do
              let(:initial_schedule_date) { Date.new(2022, 4, 1) }
              let(:initial_cadence_params) { { start_date: Date.new(2022, 3, 31), iterations_in_advance: 4, duration_in_weeks: 1 } }
              let(:expected_initial_iterations) do
                [
                  { start_date: Date.new(2022, 3, 31), duration: 1.week, state: 'current' },
                  { start_date: Date.new(2022, 3, 31) + 1.week, duration: 1.week, state: 'upcoming' },
                  { start_date: Date.new(2022, 3, 31) + 2.weeks, duration: 1.week, state: 'upcoming' },
                  { start_date: Date.new(2022, 3, 31) + 3.weeks, duration: 1.week, state: 'upcoming' },
                  { start_date: Date.new(2022, 3, 31) + 4.weeks, duration: 1.week, state: 'upcoming' }
                ]
              end

              it_behaves_like 'iterations are scheduled on an initial run'

              context "when re-executed with a smaller 'iterations_in_advance' value on a future date" do
                let(:next_schedule_date) { initial_schedule_date + 1.week } # initial_schedule_date is now in the past.
                let(:cadence_params) { initial_cadence_params.merge({ iterations_in_advance: 2 }) }
                # No change should occur. There are still 3 upcoming iterations because we never remove existing iterations.
                let(:expected_final_iterations) { expected_initial_iterations }

                it_behaves_like 'iterations are scheduled on a subsequent run'
              end
            end
          end

          context 'when cadence starts on a future date' do
            context 'when the cadence start date is the next day' do
              let(:initial_schedule_date) { Date.new(2022, 4, 1) }
              let(:initial_cadence_params) { { start_date: Date.new(2022, 4, 2), iterations_in_advance: 1, duration_in_weeks: 1 } }
              let(:expected_initial_iterations) { [{ start_date: Date.new(2022, 4, 2), duration: 1.week, state: 'upcoming' }] }

              it_behaves_like 'iterations are scheduled on an initial run'

              context 'when re-executed on a future date to start in the past' do
                let(:next_schedule_date) { initial_schedule_date } # initial_schedule_date is the current date.
                let(:cadence_params) { initial_cadence_params.merge({ start_date: initial_schedule_date }) }
                let(:expected_final_iterations) do
                  [
                    { start_date: initial_schedule_date, duration: 1.week },
                    { start_date: initial_schedule_date + 1.week, duration: 1.week }
                  ]
                end

                it_behaves_like 'iterations are scheduled on a subsequent run'
              end

              context 'when re-executed on the same date with updated cadence params' do
                let(:next_schedule_date) { initial_schedule_date }
                let(:cadence_params) { initial_cadence_params.merge({ iterations_in_advance: 2, duration_in_weeks: 2 }) }
                let(:expected_final_iterations) do
                  [
                    { start_date: Date.new(2022, 4, 2), duration: 2.weeks },
                    { start_date: Date.new(2022, 4, 2) + 2.weeks, duration: 2.weeks }
                  ]
                end

                it_behaves_like 'iterations are scheduled on a subsequent run'
              end
            end

            context 'when the cadence start date is a week later (duration_in_weeks)' do
              let(:initial_schedule_date) { Date.new(2022, 4, 1) }
              let(:initial_cadence_params) { { start_date: Date.new(2022, 4, 8), iterations_in_advance: 1, duration_in_weeks: 1 } }
              let(:expected_initial_iterations) { [{ start_date: Date.new(2022, 4, 8), duration: 1.week, state: 'upcoming' }] }

              it_behaves_like 'iterations are scheduled on an initial run'
            end
          end

          context 'when cadence starts on the current date' do
            let(:initial_schedule_date) { Date.new(2022, 4, 1) }
            let(:initial_cadence_params) { { start_date: initial_schedule_date, iterations_in_advance: 2, duration_in_weeks: 2 } }
            let(:expected_initial_iterations) do
              [
                { start_date: initial_schedule_date, duration: 2.weeks, state: 'current' },
                { start_date: initial_schedule_date + 2.weeks, duration: 2.weeks, state: 'upcoming' },
                { start_date: initial_schedule_date + 4.weeks, duration: 2.weeks, state: 'upcoming' }
              ]
            end

            it_behaves_like 'iterations are scheduled on an initial run'

            context 'when re-executed on the same date' do
              let(:next_schedule_date) { initial_schedule_date }
              let(:cadence_params) { initial_cadence_params }
              # Check idempotency; no change should occur
              let(:expected_final_iterations) { expected_initial_iterations }

              it_behaves_like 'iterations are scheduled on a subsequent run'
            end

            context 'when re-executed on a future date' do
              let(:next_schedule_date) { initial_schedule_date + 2.weeks }
              let(:cadence_params) { initial_cadence_params }
              let(:expected_final_iterations) do
                [
                  *expected_initial_iterations,
                  { start_date: initial_schedule_date + 6.weeks, duration: 2.weeks }
                ]
              end

              it_behaves_like 'iterations are scheduled on a subsequent run'
            end
          end

          context 'when new iterations need to be created' do
            let(:cadence) { automated_cadence }

            context 'when cadence has iterations but all are in the past' do
              let_it_be_with_reload(:automated_cadence) { create(:iterations_cadence, group: group, start_date: 1.week.from_now, iterations_in_advance: 2) }

              let_it_be(:past_iteration1) { create(:iteration, iterations_cadence: automated_cadence, start_date: 3.weeks.ago, due_date: 2.weeks.ago, title: 'Important iteration') }
              let_it_be(:past_iteration2) { create(:iteration, iterations_cadence: automated_cadence, start_date: past_iteration1.due_date + 1.day, due_date: past_iteration1.due_date + 1.week) }

              it 'does not modify the titles of the existing iterations (if they have any)' do
                subject

                expect(group.reload.iterations.due_date_order_asc.pluck(:title)).to eq(
                  [
                    'Important iteration',
                    nil,
                    nil,
                    nil,
                    nil
                  ])
              end
            end
          end
        end
      end
    end
  end
end
