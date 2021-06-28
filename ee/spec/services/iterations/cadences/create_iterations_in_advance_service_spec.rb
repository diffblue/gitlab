# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::CreateIterationsInAdvanceService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:inactive_cadence) { create(:iterations_cadence, group: group, active: false, automatic: true, start_date: 2.weeks.ago) }
  let_it_be(:manual_cadence) { create(:iterations_cadence, group: group, active: true, automatic: false, start_date: 2.weeks.ago) }
  let_it_be_with_reload(:automated_cadence) { create(:iterations_cadence, group: group, active: true, automatic: true, start_date: 2.weeks.ago) }

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

          context 'when new iterations need to be created' do
            context 'when no iterations exist' do
              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(3)
              end
            end

            context 'when cadence start date is in future' do
              before do
                automated_cadence.update!(iterations_in_advance: 3, start_date: 3.weeks.from_now)
              end

              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(3)
              end

              it 'sets last run date' do
                expect(automated_cadence.iterations.count).to eq(0)

                subject

                expect(automated_cadence.reload.last_run_date).to eq(automated_cadence.iterations.last(3).first.due_date)
              end
            end

            context 'when advanced iterations exist but cadence needs to create more' do
              let_it_be(:current_iteration) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: 3.days.ago, due_date: (1.week - 3.days).from_now)}
              let_it_be(:next_iteration1) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: current_iteration.due_date + 1.day, due_date: current_iteration.due_date + 1.week)}
              let_it_be(:next_iteration2) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: next_iteration1.due_date + 1.day, due_date: next_iteration1.due_date + 1.week)}

              before do
                automated_cadence.update!(iterations_in_advance: 3, duration_in_weeks: 3)
              end

              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(1)

                expect(next_iteration1.reload.duration_in_days).to eq(21)
                expect(next_iteration1.reload.start_date).to eq(current_iteration.due_date + 1.day)
                expect(next_iteration1.reload.due_date).to eq(current_iteration.due_date + 3.weeks)

                expect(next_iteration2.reload.duration_in_days).to eq(21)
                expect(next_iteration2.reload.start_date).to eq(next_iteration1.due_date + 1.day)
                expect(next_iteration2.reload.due_date).to eq(next_iteration1.due_date + 3.weeks)
              end
            end

            context 'when advanced iterations exist but cadence changes duration to a smaller one' do
              let_it_be(:current_iteration) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: 3.days.ago, due_date: (1.week - 3.days).from_now)}
              let_it_be(:next_iteration1) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: current_iteration.due_date + 1.day, due_date: current_iteration.due_date + 3.weeks)}
              let_it_be(:next_iteration2) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: next_iteration1.due_date + 1.day, due_date: next_iteration1.due_date + 3.weeks)}

              before do
                automated_cadence.update!(iterations_in_advance: 3, duration_in_weeks: 1)
              end

              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(1)

                expect(next_iteration1.reload.duration_in_days).to eq(7)
                expect(next_iteration1.reload.start_date).to eq(current_iteration.due_date + 1.day)
                expect(next_iteration1.reload.due_date).to eq(current_iteration.due_date + 1.week)

                expect(next_iteration2.reload.duration_in_days).to eq(7)
                expect(next_iteration2.reload.start_date).to eq(next_iteration1.due_date + 1.day)
                expect(next_iteration2.reload.due_date).to eq(next_iteration1.due_date + 1.week)
              end
            end

            context 'when cadence start date changes to a future date with existing iteration' do
              let_it_be(:current_iteration) { create(:iteration, group: group, iterations_cadence: automated_cadence, start_date: 3.days.ago, due_date: (2.weeks - 3.days).from_now)}

              before do
                automated_cadence.update!(start_date: 3.days.from_now, iterations_in_advance: 2, duration_in_weeks: 2)
              end

              it 'creates new iterations' do
                expect { subject }.to change(Iteration, :count).by(2)
              end
            end

            context 'when cadence has iterations but all are in the past' do
              let_it_be(:past_iteration1) { create(:iteration, group: group, title: 'Iteration 1', iterations_cadence: automated_cadence, start_date: 3.weeks.ago, due_date: 2.weeks.ago)}
              let_it_be(:past_iteration2) { create(:iteration, group: group, title: 'Iteration 2', iterations_cadence: automated_cadence, start_date: past_iteration1.due_date + 1.day, due_date: past_iteration1.due_date + 1.week)}

              before do
                automated_cadence.update!(iterations_in_advance: 2)
              end

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

              it 'sets the title correctly based on iterations count and follow-up dates' do
                subject

                initial_start_date = past_iteration2.due_date + 1.day
                initial_due_date = past_iteration2.due_date + 1.week

                expect(group.reload.iterations.due_date_order_asc.pluck(:title)).to eq([
                  'Iteration 1',
                  'Iteration 2',
                  "Iteration 3: #{(initial_start_date).strftime(Date::DATE_FORMATS[:long])} - #{initial_due_date.strftime(Date::DATE_FORMATS[:long])}",
                  "Iteration 4: #{(initial_due_date + 1.day).strftime(Date::DATE_FORMATS[:long])} - #{(initial_due_date + 1.week).strftime(Date::DATE_FORMATS[:long])}",
                  "Iteration 5: #{(initial_due_date + 1.week + 1.day).strftime(Date::DATE_FORMATS[:long])} - #{(initial_due_date + 2.weeks).strftime(Date::DATE_FORMATS[:long])}"
                ])
              end

              context 'when cadence changes duration' do
                before do
                  subject
                  automated_cadence.update!(duration_in_weeks: 3)
                  automated_cadence.reload
                end

                it 'adjusts iteration titles for iterations that are autogenerated and have the dates in the title' do
                  subject
                  # change duration and expect the titles for iterations containing dates in title to change
                  described_class.new(user, automated_cadence).execute

                  initial_start_date = past_iteration2.due_date + 1.day
                  initial_due_date = past_iteration2.due_date + 1.week

                  expect(group.reload.iterations.due_date_order_asc.pluck(:title)).to eq([
                    'Iteration 1',
                    'Iteration 2',
                    "Iteration 3: #{(initial_start_date).strftime(Date::DATE_FORMATS[:long])} - #{initial_due_date.strftime(Date::DATE_FORMATS[:long])}",
                    "Iteration 4: #{(initial_due_date + 1.day).strftime(Date::DATE_FORMATS[:long])} - #{(initial_due_date + 3.weeks).strftime(Date::DATE_FORMATS[:long])}",
                    "Iteration 5: #{(initial_due_date + 3.weeks + 1.day).strftime(Date::DATE_FORMATS[:long])} - #{(initial_due_date + 6.weeks).strftime(Date::DATE_FORMATS[:long])}"
                  ])
                end
              end

              it 'sets the states correctly based on iterations dates' do
                subject

                expect(group.reload.iterations.order(:start_date).map(&:state)).to eq(%w[closed closed current upcoming upcoming])
              end
            end
          end
        end
      end
    end
  end
end
