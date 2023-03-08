# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::EditService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let_it_be_with_refind(:oncall_schedule) { create(:incident_management_oncall_schedule, :utc, project: project) }
  let_it_be_with_refind(:oncall_rotation) { create(:incident_management_oncall_rotation, :with_participants, schedule: oncall_schedule, participants_count: 2) }

  let(:current_user) { user_with_permissions }
  let(:params) { rotation_params }
  let(:service) { described_class.new(oncall_rotation, current_user, params) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(user_with_permissions)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect { execute }.not_to change { oncall_rotation.reload.updated_at }
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    context 'no license' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call rotations'
    end

    context 'user does not have permission' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to edit an on-call rotation in this project'
    end

    context 'adding one participant' do
      let(:participant_to_add) { build(:incident_management_oncall_participant, rotation: oncall_rotation, user: user_with_permissions) }
      let(:params) { rotation_params(participants: oncall_rotation.participants.to_a.push(participant_to_add)) }

      it 'adds the participant to the rotation' do
        subject

        attributes_to_match = participant_to_add.attributes.except('id')

        expect(oncall_rotation.participants.not_removed).to include(an_object_having_attributes(attributes_to_match))
      end

      it 'updates the rotation updated_at' do
        expect { subject }.to change { oncall_rotation.updated_at }
      end

      context 'new participant has a validation error' do
        # Participant with nil color palette
        let(:participant_to_add) { build(:incident_management_oncall_participant, rotation: oncall_rotation, user: user_with_permissions, color_palette: nil) }

        it_behaves_like 'error response', "Color palette can't be blank"
      end

      context 'rotation params have a validation error' do
        let(:rotation_edit_params) { { name: '' } }
        let(:params) { rotation_params(edit_params: rotation_edit_params, participants: oncall_rotation.participants.to_a.push(participant_to_add)) }

        it 'does not add the participant' do
          expect { subject }.not_to change(IncidentManagement::OncallParticipant, :count)
        end

        it_behaves_like 'error response', "Name can't be blank"
      end
    end

    context 'adding too many participants' do
      let(:participant_to_add) { build(:incident_management_oncall_participant, rotation: oncall_rotation, user: user_with_permissions) }
      let(:params) { rotation_params(participants: Array.new(described_class::MAXIMUM_PARTICIPANTS + 1, participant_to_add)) }

      it 'has an informative error message' do
        expect { execute }.not_to change { oncall_rotation.reload.updated_at }
        expect(execute).to be_error
        expect(execute.message).to eq("A maximum of #{described_class::MAXIMUM_PARTICIPANTS} participants can be added")
      end
    end

    context 'when adding a duplicate user' do
      let(:existing_participant_user) { oncall_rotation.participants.first.user }
      let(:participant_to_add) { build(:incident_management_oncall_participant, rotation: oncall_rotation, user: existing_participant_user) }
      let(:params) { rotation_params(participants: oncall_rotation.participants.to_a.push(participant_to_add)) }

      it_behaves_like 'error response', 'A user can only participate in a rotation once'
    end

    context 'when adding a user that do not have permissions' do
      let(:another_user_with_permission) do
        new_user = create(:user)
        project.add_maintainer(new_user)
        new_user
      end

      let(:participant_to_add) { build(:incident_management_oncall_participant, rotation: oncall_rotation, user: another_user_with_permission) }
      let(:participant_without_permissions_to_add) { build(:incident_management_oncall_participant, rotation: oncall_rotation, user: user_without_permissions) }
      let(:params) { rotation_params(participants: oncall_rotation.participants.to_a.push(participant_to_add, participant_without_permissions_to_add)) }

      it_behaves_like 'error response', 'A participant has insufficient permissions to access the project'

      it 'does not modify the rotation' do
        expect { subject }.not_to change { oncall_rotation.participants.reload }
      end
    end

    context 'removing one participant' do
      let(:participant_to_keep) { oncall_rotation.participants.first }
      let(:participant_to_remove) { oncall_rotation.participants.last }
      let(:params) { rotation_params(participants: [participant_to_keep]) }

      it 'soft-removes the participant from the rotation' do
        subject

        expect(participant_to_remove.reload.is_removed).to eq(true)
        expect(participant_to_keep.reload.is_removed).to eq(false)
      end
    end

    context 'removing all participants' do
      let(:params) { rotation_params(participants: []) }

      it 'soft-deletes all the rotation participants' do
        subject

        expect(oncall_rotation.participants.not_removed).to be_empty
        expect(oncall_rotation.participants.removed).to eq(oncall_rotation.participants)
      end
    end

    context 'participant param is nil' do
      let(:params) { rotation_params(participants: nil) }

      it 'does not modify the participants' do
        subject

        expect(oncall_rotation.participants.not_removed).to eq(oncall_rotation.participants)
        expect(oncall_rotation.participants.removed).to be_empty
      end
    end

    context 'editing rotation attributes' do
      let(:params) { { name: 'Changed rotation', length: 7, length_unit: 'days', starts_at: 1.week.from_now.change(sec: 0), ends_at: 1.month.from_now.change(sec: 0) } }

      it 'updates the rotation to match the params' do
        subject

        expect(oncall_rotation.reload).to have_attributes(params)
      end

      context 'with a validation error' do
        let(:params) { { name: '', starts_at: 1.week.from_now } }

        it_behaves_like 'error response', "Name can't be blank"

        it 'updates the rotation to match the params' do
          subject

          expect(oncall_rotation.reload).not_to have_attributes(params)
        end
      end
    end

    context 'for an already-started rotation' do
      let(:active_period_shift) { { starts_at: oncall_rotation.starts_at.change(hour: 8), ends_at: oncall_rotation.starts_at.change(hour: 17) } }

      around do |example|
        travel_to(updated_at) { example.run }
      end

      context 'when the "current" shift and new "current" shift would conflict' do
        let(:updated_at) { 8.days.after(oncall_rotation.starts_at) }
        let(:params) { { length: 1, length_unit: 'weeks' } }

        let(:previous_completed_shift) { { starts_at: oncall_rotation.starts_at, ends_at: 5.days.after(oncall_rotation.starts_at) } }
        let(:previous_current_shift) { { starts_at: 5.days.after(oncall_rotation.starts_at), ends_at: updated_at } }
        let(:new_current_shift) { { starts_at: updated_at, ends_at: 2.weeks.after(oncall_rotation.starts_at) } }

        it 'ensures the shift history is up-to-date, ends the current shift, and starts the new shift partway' do
          expect(execute).to be_success

          first_shift, second_shift, third_shift = oncall_rotation.shifts
          expect(oncall_rotation.shifts.length).to eq(3)
          expect(first_shift).to have_attributes(previous_completed_shift)
          expect(second_shift).to have_attributes(previous_current_shift)
          expect(third_shift).to have_attributes(new_current_shift)
        end
      end

      context 'when the next shift has not started' do
        let(:updated_at) { 3.days.after(oncall_rotation.starts_at).change(hour: 20) }
        let(:params) { { active_period_start: active_period_shift[:starts_at], active_period_end: active_period_shift[:ends_at] } }

        let(:previous_current_shift) { { starts_at: oncall_rotation.starts_at, ends_at: updated_at } }

        it 'ends the original "current" shift and does not save a new shift' do
          expect(execute).to be_success

          first_shift = oncall_rotation.shifts.first
          expect(oncall_rotation.shifts.length).to eq(1)
          expect(first_shift).to have_attributes(previous_current_shift)
        end
      end

      context 'when all previous shifts have already ended' do
        let_it_be(:starts_at) { Time.current.next_day.change(hour: 3, usec: 0) }
        let_it_be_with_refind(:oncall_rotation) { create(:incident_management_oncall_rotation, :with_participants, :with_active_period, schedule: oncall_schedule, starts_at: starts_at) }

        let(:updated_at) { starts_at.next_day }
        let(:params) { { active_period_start: nil, active_period_end: nil } }

        let(:new_current_shift) { { starts_at: updated_at, ends_at: 5.days.after(oncall_rotation.starts_at) } }

        it 'starts the new "current" shift partway' do
          expect(execute).to be_success

          first_shift, second_shift = oncall_rotation.shifts
          expect(oncall_rotation.shifts.length).to eq(2)
          expect(first_shift).to have_attributes(active_period_shift)
          expect(second_shift).to have_attributes(new_current_shift)
        end

        context 'when there is not a new shift' do
          let(:params) { { ends_at: updated_at } }

          it 'does not modify or save any shifts' do
            expect(execute).to be_success

            first_shift = oncall_rotation.shifts.first
            expect(oncall_rotation.shifts.length).to eq(1)
            expect(first_shift).to have_attributes(active_period_shift)
          end
        end
      end
    end
  end

  private

  def rotation_params(participants: nil, edit_params: {})
    # if participant params given, generate them
    # otherwise use saved params
    edit_params.merge(participants: participant_params(participants))
  end

  def participant_params(participants)
    return unless participants

    participants.map do |participant|
      {
        user: participant.user,
        color_palette: participant.color_palette,
        color_weight: participant.color_weight
      }
    end
  end
end
