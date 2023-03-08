# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::RemoveParticipantService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:schedule) { create(:incident_management_oncall_schedule, project: project) }
  let_it_be(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule, length: 5, length_unit: :days) }
  let_it_be(:other_participant) { create(:incident_management_oncall_participant, rotation: rotation) }
  let_it_be(:participant) { create(:incident_management_oncall_participant, rotation: rotation, user: user) }

  let(:service) { described_class.new(rotation, user) }

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  context 'user is not a participant' do
    let(:other_user) { create(:user) }
    let(:service) { described_class.new(rotation, other_user) }

    it 'does not send a notification' do
      expect(NotificationService).not_to receive(:oncall_user_removed)
      execute
    end
  end

  it 'marks the participant as removed' do
    expect { execute }.to change { participant.reload.is_removed }.to(true)
  end

  context 'with existing shift by other participant, and current shift by user to be removed' do
    let(:current_date) { 1.week.after(rotation.starts_at) }

    around do |example|
      travel_to(current_date) { example.run }
    end

    # Create an historial shift (other participant)
    let!(:historical_shift) { create(:incident_management_oncall_shift, rotation: rotation, participant: other_participant, starts_at: rotation.starts_at, ends_at: ends_at(rotation.starts_at)) }

    context 'with historial and current shift', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/343506' do
      # Create a current shift (particpant being removed)
      let!(:current_shift) { create(:incident_management_oncall_shift, rotation: rotation, participant: participant, starts_at: historical_shift.ends_at, ends_at: ends_at(historical_shift.ends_at)) }

      it 'does not affect existing shifts, ends the current shift, and starts the new shift', :aggregate_failures do
        historical_shift, current_shift = rotation.shifts.order(starts_at: :asc)
        expect(historical_shift.participant).to eq(other_participant)
        expect(current_shift.participant).to eq(participant)
        expect(current_shift.ends_at).not_to be_like_time(Time.current)

        expect { execute }.not_to change { historical_shift.reload }

        new_shift = rotation.shifts.order(starts_at: :asc).last

        expect(current_shift.reload.ends_at).to be_like_time(Time.current)
        expect(new_shift.participant).to eq(other_participant)
        expect(new_shift.starts_at).to be_like_time(Time.current)
        expect(new_shift.ends_at).to be_like_time(ends_at(historical_shift.ends_at))
      end
    end

    context 'when current shift has not been created', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/343506' do
      it 'creates the current shift and cuts it short' do
        expect { execute }.to change { rotation.shifts.count }.from(1).to(3)

        current_shift, new_current_shift = rotation.shifts.order(starts_at: :asc).last(2)

        expect(current_shift.participant).to eq(participant)
        expect(current_shift.ends_at).to be_like_time(Time.current)

        expect(new_current_shift.participant).to eq(other_participant)
        expect(new_current_shift.starts_at).to be_like_time(Time.current)
        expect(new_current_shift.ends_at).to be_like_time(ends_at(current_shift.starts_at))
      end
    end

    def ends_at(starts_at)
      starts_at + rotation.shift_cycle_duration
    end
  end
end
