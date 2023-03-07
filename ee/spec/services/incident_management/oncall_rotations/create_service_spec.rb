# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::CreateService, feature_category: :incident_management do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:schedule) { create(:incident_management_oncall_schedule, project: project) }
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:current_user) { user_with_permissions }

  let(:execution_time) { DateTime.new(2021, 3, 1, 4, 5, 6) }
  let(:starts_at) { DateTime.new(2021, 3, 1) }

  let(:participants) do
    [
      {
        user: current_user,
        color_palette: 'blue',
        color_weight: '500'
      }
    ]
  end

  let(:params) { { name: 'On-call rotation', starts_at: starts_at, ends_at: 1.month.after(starts_at), length: '1', length_unit: 'days' }.merge(participants: participants) }
  let(:service) { described_class.new(schedule, project, current_user, params) }

  before_all do
    project.add_maintainer(user_with_permissions)
  end

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'does not save the rotation and has an informative message' do
        expect { execute }.not_to change(IncidentManagement::OncallRotation, :count)
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    subject(:execute) do
      travel_to(execution_time) { service.execute }
    end

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to create an on-call rotation for this project'
    end

    context 'when the current_user does not have permissions to create on-call schedules' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to create an on-call rotation for this project'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call rotations'
    end

    context 'when an on-call rotation already exists' do
      let!(:oncall_rotation) { create(:incident_management_oncall_rotation, schedule: schedule, name: 'On-call rotation') }

      it_behaves_like 'error response', 'Name has already been taken'
    end

    context 'when too many participants' do
      before do
        stub_const('IncidentManagement::OncallRotations::CreateService::MAXIMUM_PARTICIPANTS', 0)
      end

      it 'has an informative error message' do
        expect(execute).to be_error
        expect(execute.message).to eq("A maximum of #{IncidentManagement::OncallRotations::SharedRotationLogic::MAXIMUM_PARTICIPANTS} participants can be added")
      end
    end

    context 'when participant cannot read project' do
      let_it_be(:other_user) { create(:user) }

      let(:participants) do
        [
          {
            user: other_user,
            color_palette: 'blue',
            color_weight: '500'
          }
        ]
      end

      it_behaves_like 'error response', 'A participant has insufficient permissions to access the project'
    end

    context 'participant is included multiple times' do
      let(:participants) do
        [
          {
            user: current_user,
            color_palette: 'blue',
            color_weight: '500'
          },
          {
            user: current_user,
            color_palette: 'magenta',
            color_weight: '500'
          }
        ]
      end

      it_behaves_like 'error response', 'A user can only participate in a rotation once'
    end

    context 'with valid params' do
      shared_examples 'successfully creates rotation' do
        it 'successfully creates an on-call rotation with participants' do
          expect(execute).to be_success

          oncall_rotation = execute.payload[:oncall_rotation]
          expect(oncall_rotation).to be_a(::IncidentManagement::OncallRotation)
          expect(oncall_rotation.name).to eq('On-call rotation')
          expect(oncall_rotation.starts_at).to eq(starts_at)
          expect(oncall_rotation.ends_at).to eq(1.month.after(starts_at))
          expect(oncall_rotation.length).to eq(1)
          expect(oncall_rotation.length_unit).to eq('days')

          expect(oncall_rotation.participants.reload.length).to eq(1)
          expect(oncall_rotation.participants.first).to have_attributes(
            **participants.first,
            rotation: oncall_rotation,
            persisted?: true
          )
        end
      end

      it_behaves_like 'successfully creates rotation'

      context 'with an active period given' do
        let(:active_period_start) { '08:00' }
        let(:active_period_end) { '17:00' }

        before do
          params[:active_period_start] = active_period_start
          params[:active_period_end] = active_period_end
        end

        shared_examples 'saved the active period times' do
          it 'saves the active period times' do
            oncall_rotation = execute.payload[:oncall_rotation]

            expect(oncall_rotation.active_period_start.strftime('%H:%M')).to eq(active_period_start)
            expect(oncall_rotation.active_period_end.strftime('%H:%M')).to eq(active_period_end)
          end
        end

        it_behaves_like 'successfully creates rotation'
        it_behaves_like 'saved the active period times'

        context 'when end active time is before start active time' do
          let(:active_period_start) { '17:00' }
          let(:active_period_end) { '08:00' }

          it_behaves_like 'successfully creates rotation'
          it_behaves_like 'saved the active period times'
        end

        context 'when only active period end time is set' do
          let(:active_period_start) { nil }

          it_behaves_like 'error response', "Active period start can't be blank"
        end

        context 'when only active period start time is set' do
          let(:active_period_end) { nil }

          it_behaves_like 'error response', "Active period end can't be blank"
        end
      end

      context 'for an in-progress rotation' do
        it 'trims & saves the current shift' do
          oncall_rotation = execute.payload[:oncall_rotation]

          expect(oncall_rotation.shifts.length).to eq(1)
          expect(oncall_rotation.shifts.first).to have_attributes(
            starts_at: oncall_rotation.reload.created_at,
            ends_at: oncall_rotation.starts_at.next_day
          )
        end
      end
    end
  end
end
