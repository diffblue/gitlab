# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::PersistShiftsJob, feature_category: :incident_management do
  include OncallHelpers

  let(:worker) { described_class.new }
  let(:rotation_id) { rotation.id }

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  describe '#perform' do
    subject(:perform) { worker.perform(rotation_id) }

    context 'unknown rotation' do
      let(:rotation_id) { non_existing_record_id }

      it { is_expected.to be_nil }

      it 'does not create shifts' do
        expect { perform }.not_to change { IncidentManagement::OncallShift.count }
      end
    end

    context 'when rotation has no saved shifts' do
      context 'and rotation was created before it "started"' do
        let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participants, created_at: 1.day.ago) }

        it 'creates shift' do
          expect { perform }.to change { rotation.shifts.count }.by(1)
          expect(rotation.shifts.first.starts_at).to eq(rotation.starts_at)
        end
      end

      context 'and rotation "started" before it was created' do
        let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participants, starts_at: 1.month.ago) }

        it 'creates shift without backfilling' do
          expect { perform }.to change { rotation.shifts.count }.by(1)

          first_shift = rotation.shifts.first

          expect(first_shift.starts_at).to be > rotation.starts_at
          expect(rotation.created_at).to be_between(first_shift.starts_at, first_shift.ends_at)
        end
      end

      context 'and rotation with active period is updated to start in the past instead of the future while no shifts are in progress' do
        let_it_be(:monday) { Time.current.beginning_of_week }
        let_it_be(:created_at) { monday.change(hour: 5) }
        let_it_be(:starts_at) { monday.next_week(:tuesday).beginning_of_day }
        let_it_be(:updated_at) { monday.next_week(:friday).change(hour: 6) }
        let_it_be_with_reload(:rotation) do
          # Mimic start time update. Imagine the old value was Saturday @ 00:00.
          create(
            :incident_management_oncall_rotation,
            :with_active_period, # 8:00 - 17:00
            :with_participants,
            :utc,
            created_at: created_at, # Monday @ 5:00
            starts_at: starts_at, # Tuesday @ 00:00
            updated_at: updated_at # Friday @ 6:00
          )
        end

        let_it_be(:active_period) { active_period_for_date_with_tz(updated_at, rotation) }

        around do |example|
          travel_to(current_time) { example.run }
        end

        context 'before the next shift has started' do
          let(:current_time) { 1.minute.before(active_period[0]) }

          it 'does not create shifts' do
            expect { perform }.not_to change { IncidentManagement::OncallShift.count }
          end
        end

        context 'once the next shift has started' do
          let(:current_time) { active_period[0] }

          it 'creates only the next shift and does not backfill shifts which did not happen' do
            expect { perform }.to change { rotation.shifts.count }.by(1)
            expect(rotation.shifts.first.starts_at).to eq(active_period[0])
            expect(rotation.shifts.first.ends_at).to eq(active_period[1])
          end
        end
      end
    end

    context 'when rotation has saved shifts' do
      let_it_be(:existing_shift) { create(:incident_management_oncall_shift, :utc) }
      let_it_be_with_reload(:rotation) { existing_shift.rotation }

      context 'when current time is during a saved shift' do
        it 'does not create shifts' do
          expect { perform }.not_to change { IncidentManagement::OncallShift.count }
        end
      end

      context 'when current time is not during a saved shift' do
        around do |example|
          travel_to(5.minutes.after(existing_shift.ends_at)) { example.run }
        end

        it 'creates shift' do
          expect { perform }.to change { rotation.shifts.count }.by(1)
          expect(rotation.shifts.first).to eq(existing_shift)
          expect(rotation.shifts.second.starts_at).to eq(existing_shift.ends_at)
        end
      end

      # Unexpected case. If the job is delayed, we'll still
      # fill in the correct shift history.
      context 'when current time is several shifts after the last saved shift' do
        around do |example|
          travel_to(existing_shift.ends_at + (3 * rotation.shift_cycle_duration)) { example.run }
        end

        it 'creates multiple shifts' do
          expect { perform }.to change { rotation.shifts.count }.by(3)

          first_shift,
          second_shift,
          third_shift,
          fourth_shift = rotation.shifts.order(:starts_at)

          expect(rotation.shifts.length).to eq(4)
          expect(first_shift).to eq(existing_shift)
          expect(second_shift.starts_at).to eq(existing_shift.ends_at)
          expect(third_shift.starts_at).to eq(existing_shift.ends_at + rotation.shift_cycle_duration)
          expect(fourth_shift.starts_at).to eq(existing_shift.ends_at + (2 * rotation.shift_cycle_duration))
        end
      end

      context 'when current time is after a rotation has re-started after an edit' do
        let_it_be(:new_starts_at) { rotation.starts_at + 3 * rotation.shift_cycle_duration }
        let_it_be(:updated_at) { rotation.starts_at + rotation.shift_cycle_duration }

        let(:current_time) { 2.minutes.after(new_starts_at) }

        before do
          # Mimic start time update which occurred after a
          # shift had already completed, pushing the start time
          # out into the future.
          rotation.update!(starts_at: new_starts_at, updated_at: updated_at)
        end

        around do |example|
          travel_to(current_time) { example.run }
        end

        it 'creates only the next shift and does not backfill' do
          expect { perform }.to change { rotation.shifts.count }.by(1)
          expect(rotation.shifts.first).to eq(existing_shift)
          expect(rotation.shifts.second.starts_at).to eq(rotation.starts_at)
          expect(rotation.shifts.second.ends_at).to eq(rotation.starts_at + rotation.shift_cycle_duration)
        end
      end

      context 'when rotation has active periods' do
        let_it_be(:starts_at) { Time.current.beginning_of_day }
        let_it_be_with_reload(:rotation) do
          create(
            :incident_management_oncall_rotation,
            :with_participants,
            :utc,
            :with_active_period, # 8:00-17:00
            starts_at: starts_at
          )
        end

        let_it_be(:active_period) { active_period_for_date_with_tz(starts_at, rotation) }
        let_it_be(:existing_shift) do
          create(
            :incident_management_oncall_shift,
            rotation: rotation,
            participant: rotation.participants.first,
            starts_at: active_period[0],
            ends_at: active_period[1]
          )
        end

        around do |example|
          travel_to(current_time) { example.run }
        end

        context 'when current time is in the active period' do
          let(:current_time) { existing_shift.starts_at.next_day.change(hour: 10) } # active from 8-17

          it 'creates the next shift' do
            expect { perform }.to change { rotation.shifts.count }.by(1)
            expect(rotation.shifts.first).to eq(existing_shift)
            expect(rotation.shifts.second.starts_at).to eq(1.day.after(existing_shift.starts_at))
            expect(rotation.shifts.second.ends_at).to eq(1.day.after(existing_shift.ends_at))
          end

          context 'when rotation was previously ended but is now in progress' do
            let_it_be(:updated_at) { rotation.reload.starts_at + 3 * rotation.shift_cycle_duration }

            let(:current_time) { updated_at.change(hour: 8, min: 2) }
            let(:expected_shift_start) { updated_at.change(hour: existing_shift.starts_at.hour) }
            let(:expected_shift_end) { updated_at.change(hour: existing_shift.ends_at.hour) }

            before do
              # Mimic end time update. Imagine rotation previously ended
              # after a single shift, but now it has no end date.
              rotation.update!(updated_at: updated_at)
            end

            it 'creates only the next shift and does not backfill' do
              expect { perform }.to change { rotation.shifts.count }.by(1)
              expect(rotation.shifts.first).to eq(existing_shift)
              # the second saved shift should be the first one after the
              # rotation was updated and cover the whole active period
              expect(rotation.shifts.second.starts_at).to eq(expected_shift_start)
              expect(rotation.shifts.second.ends_at).to eq(expected_shift_end)
            end
          end
        end

        context 'when the current time is not in the active period' do
          let(:current_time) { Time.current.beginning_of_day }

          it 'does not create shifts' do
            expect { perform }.not_to change { IncidentManagement::OncallShift.count }
          end
        end
      end
    end
  end
end
