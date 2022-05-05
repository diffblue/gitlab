# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::CreateIterationsInAdvanceService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:inactive_cadence) { create(:iterations_cadence, group: group, active: false, automatic: true, start_date: 2.weeks.ago) }
  let_it_be(:manual_cadence) { build(:iterations_cadence, group: group, active: true, automatic: false, start_date: 2.weeks.ago).tap { |cadence| cadence.save!(validate: false) } }
  let_it_be_with_reload(:automated_cadence) { create(:iterations_cadence, group: group, active: true, automatic: true, start_date: 2.weeks.ago) }

  let(:sequences) { (1..cadence.iterations.size).to_a }
  let(:ordered_iterations) { cadence.iterations.order(:start_date) }
  let(:ordered_sequences) { ordered_iterations.map(&:sequence) }
  let(:ordered_dates) { ordered_iterations.map { |i| [i.start_date, i.due_date] } }
  let(:expected_last_run_date) { cadence.iterations.with_start_date_after(today).last(cadence.iterations_in_advance).first.due_date }

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
        end

        context 'with inactive cadence' do
          let(:cadence) { inactive_cadence }

          it 'returns error' do
            expect(subject).to be_error
          end
        end

        context 'with automatic and active cadence' do
          let(:cadence) { automated_cadence }

          it 'does not return error' do
            expect(subject).not_to be_error
          end

          context 'when no iterations need to be created' do
            let_it_be(:iteration) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: 1.week.from_now, due_date: 2.weeks.from_now)}

            it 'does not create any new iterations' do
              expect { subject }.not_to change(Iteration, :count)
            end
          end

          shared_examples 'iterations are scheduled' do
            let(:days_of_week) { ordered_iterations.map { |i| i.start_date.wday }.uniq }
            let(:expected_dates) { expected_iterations.map { |i| [i[:start_date], i[:start_date] + i[:duration] - 1] } }

            it 'correctly manages and schedules iterations', :aggregate_failures do
              # Sanity check: ensure that all iterations start on the same day of the week and have correct sequences
              expect(ordered_sequences).to eq(sequences)
              expect(days_of_week.one?).to be(true)
              expect(days_of_week.first).to be(cadence.start_date.wday)

              expect(ordered_dates).to eq(expected_dates)
              expect(cadence.last_run_date).to eq(expected_last_run_date)
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
            let(:cadence) { create(:iterations_cadence, group: group, **initial_cadence_params) }
            let(:initial_schedule_date) { Date.new(2022, 4, 1) }
            let(:initial_cadence_params) { { start_date: Date.new(2022, 3, 28), iterations_in_advance: 4, duration_in_weeks: 1 } }
            let(:expected_initial_iterations) do
              [
                { start_date: Date.new(2022, 3, 28), duration: 1.week },
                { start_date: Date.new(2022, 3, 28) + 1.week, duration: 1.week },
                { start_date: Date.new(2022, 3, 28) + 2.weeks, duration: 1.week },
                { start_date: Date.new(2022, 3, 28) + 3.weeks, duration: 1.week },
                { start_date: Date.new(2022, 3, 28) + 4.weeks, duration: 1.week }
              ]
            end

            it_behaves_like 'iterations are scheduled on an initial run'

            context "when re-executed with a smaller 'iterations_in_advance' value on a future date" do
              let(:next_schedule_date) { initial_schedule_date + 1.week } # initial_schedule_date is now in the past.
              let(:cadence_params) { initial_cadence_params.merge({ iterations_in_advance: 2 }) }
              let(:expected_final_iterations) do
                [
                  expected_initial_iterations[0],
                  expected_initial_iterations[1],
                  # There are 3 future iterations even though "terations_in_advance: 2" because we never remove existing iterations.
                  { start_date: Date.new(2022, 3, 28) + 2.weeks, duration: 1.week },
                  { start_date: Date.new(2022, 3, 28) + 3.weeks, duration: 1.week },
                  { start_date: Date.new(2022, 3, 28) + 4.weeks, duration: 1.week }
                ]
              end

              it_behaves_like 'iterations are scheduled on a subsequent run'
            end
          end

          context 'when cadence starts on a future date' do
            let(:cadence) { create(:iterations_cadence, group: group, **initial_cadence_params) }
            let(:initial_schedule_date) { Date.new(2022, 4, 1) }
            let(:initial_cadence_params) { { start_date: Date.new(2022, 4, 5), iterations_in_advance: 1, duration_in_weeks: 1 } }
            let(:expected_initial_iterations) { [{ start_date: Date.new(2022, 4, 5), duration: 1.week }] }

            it_behaves_like 'iterations are scheduled on an initial run'
          end

          context 'when new iterations need to be created' do
            let(:cadence) { automated_cadence }

            shared_examples "creating iterations with sequences" do
              let(:sequences) { (1..cadence.iterations.size).to_a }

              it 'creates iterations with correct sequences' do
                subject

                expect(ordered_sequences).to eq(sequences)
              end
            end

            context 'when advanced iterations exist but cadence needs to create more' do
              let_it_be_with_reload(:automated_cadence) { create(:iterations_cadence, group: group, start_date: 2.weeks.ago, iterations_in_advance: 3, duration_in_weeks: 3) }

              let_it_be(:current_iteration) { create(:iteration, iterations_cadence: automated_cadence, start_date: 3.days.ago, due_date: (1.week - 3.days).from_now)}
              let_it_be(:next_iteration1) { create(:iteration, iterations_cadence: automated_cadence, start_date: current_iteration.due_date + 1.day, due_date: current_iteration.due_date + 1.week)}
              let_it_be(:next_iteration2) { create(:iteration, iterations_cadence: automated_cadence, start_date: next_iteration1.due_date + 1.day, due_date: next_iteration1.due_date + 1.week)}

              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(1)

                expect(next_iteration1.reload.duration_in_days).to eq(21)
                expect(next_iteration1.reload.start_date).to eq(current_iteration.due_date + 1.day)
                expect(next_iteration1.reload.due_date).to eq(current_iteration.due_date + 3.weeks)

                expect(next_iteration2.reload.duration_in_days).to eq(21)
                expect(next_iteration2.reload.start_date).to eq(next_iteration1.due_date + 1.day)
                expect(next_iteration2.reload.due_date).to eq(next_iteration1.due_date + 3.weeks)
              end

              it_behaves_like "creating iterations with sequences"
            end

            context 'when advanced iterations exist but cadence changes duration to a smaller one' do
              let_it_be_with_reload(:automated_cadence) { create(:iterations_cadence, group: group, start_date: 2.weeks.ago, iterations_in_advance: 3, duration_in_weeks: 1) }

              let_it_be(:current_iteration) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: 3.days.ago, due_date: (1.week - 3.days).from_now)}
              let_it_be(:next_iteration1) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: current_iteration.due_date + 1.day, due_date: current_iteration.due_date + 3.weeks)}
              let_it_be(:next_iteration2) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: next_iteration1.due_date + 1.day, due_date: next_iteration1.due_date + 3.weeks)}

              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(1)

                expect(next_iteration1.reload.duration_in_days).to eq(7)
                expect(next_iteration1.reload.start_date).to eq(current_iteration.due_date + 1.day)
                expect(next_iteration1.reload.due_date).to eq(current_iteration.due_date + 1.week)

                expect(next_iteration2.reload.duration_in_days).to eq(7)
                expect(next_iteration2.reload.start_date).to eq(next_iteration1.due_date + 1.day)
                expect(next_iteration2.reload.due_date).to eq(next_iteration1.due_date + 1.week)
              end

              it_behaves_like "creating iterations with sequences"
            end

            context 'when cadence has iterations but all are in the past' do
              let_it_be_with_reload(:automated_cadence) { create(:iterations_cadence, group: group, start_date: 2.weeks.ago, iterations_in_advance: 2) }

              let_it_be(:past_iteration1) { create(:iteration, group: group, title: 'Important iteration', iterations_cadence: automated_cadence, start_date: 3.weeks.ago, due_date: 2.weeks.ago)}
              let_it_be(:past_iteration2) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: past_iteration1.due_date + 1.day, due_date: past_iteration1.due_date + 1.week)}

              it 'creates new iterations' do
                # because last iteration ended 1 week ago, we generate one iteration for current week and 2 in advance
                expect { subject }.to change(Iteration, :count).by(3)
              end

              it 'updates cadence last_run_date' do
                # because cadence is set to generate 2 iterations in advance, we set last run date to due_date of the
                # penultimate
                subject

                expect(automated_cadence.reload.last_run_date).to eq(automated_cadence.reload.iterations.last(2).first.due_date)
              end

              it 'does not modify the titles of the existing iterations (if they have any)' do
                subject

                expect(group.reload.iterations.due_date_order_asc.pluck(:title)).to eq([
                  'Important iteration',
                  nil,
                  nil,
                  nil,
                  nil
                ])
              end

              it 'sets the states correctly based on iterations dates' do
                subject

                expect(group.reload.iterations.order(:start_date).map(&:state)).to eq(%w[closed closed current upcoming upcoming])
              end

              it_behaves_like "creating iterations with sequences"
            end
          end
        end
      end
    end
  end
end
