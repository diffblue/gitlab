# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallSchedules::UpdateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be_with_reload(:oncall_schedule) { create(:incident_management_oncall_schedule, :utc, project: project) }

  let(:current_user) { user_with_permissions }
  let(:new_timezone) { 'America/New_York' }
  let(:params) { { name: 'Updated name', description: 'Updated description', timezone: new_timezone } }
  let(:service) { described_class.new(project: project, current_user: current_user, params: params) }

  before do
    stub_licensed_features(oncall_schedules: true)
    project.add_maintainer(user_with_permissions)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    subject(:execute) { service.execute(oncall_schedule) }

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to update an on-call schedule for this project'
    end

    context 'when the current_user does not have permissions to update on-call schedules' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to update an on-call schedule for this project'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call schedules'
    end

    context 'when an on-call schedule witht the same name already exists' do
      before do
        create(:incident_management_oncall_schedule, project: project, name: params[:name])
      end

      it_behaves_like 'error response', 'Name has already been taken'
    end

    context 'with valid params' do
      it 'successfully creates an on-call schedule' do
        response = execute
        payload = response.payload
        oncall_schedule.reload

        expect(response).to be_success
        expect(payload[:oncall_schedule]).to eq(oncall_schedule)
        expect(oncall_schedule).to be_a(::IncidentManagement::OncallSchedule)
        expect(oncall_schedule.name).to eq(params[:name])
        expect(oncall_schedule.description).to eq(params[:description])
        expect(oncall_schedule.timezone).to eq(params[:timezone])
      end

      context 'schedule has a rotation' do
        # Setting fixed timezone for rotation active period updates
        around do |example|
          travel_to Time.utc(2021, 03, 22, 0, 0)

          example.run
        end

        let_it_be_with_reload(:oncall_rotation) { create(:incident_management_oncall_rotation, :with_active_period, schedule: oncall_schedule) }

        shared_examples 'updates the rotation active periods' do |new_start_time, new_end_time|
          it 'updates the rotation active periods with new timezone' do
            initial_start_time = oncall_rotation.reload.attributes_before_type_cast['active_period_start']
            initial_end_time = oncall_rotation.attributes_before_type_cast['active_period_end']

            expect { execute }.to change { oncall_rotation.reload.attributes_before_type_cast['active_period_start'] }.from(initial_start_time).to("#{new_start_time}:00")
             .and change { oncall_rotation.reload.attributes_before_type_cast['active_period_end'] }.from(initial_end_time).to("#{new_end_time}:00")
             .and change { oncall_schedule.reload.timezone }.to(new_timezone)
          end
        end

        # This expects the active periods are updated according to the date above (22nd March, 2021 in the new timezone).
        it_behaves_like 'updates the rotation active periods', '04:00', '13:00'

        context 'from non-overnight shifts to overnight' do
          let(:new_timezone) { 'Pacific/Auckland' }

          it_behaves_like 'updates the rotation active periods', '21:00', '06:00'
        end

        context 'from overnight shifts to non-overnight' do
          before do
            oncall_rotation.update!(active_period_start: '21:00', active_period_end: '06:00')
          end

          let(:new_timezone) { 'Pacific/Auckland' }

          it_behaves_like 'updates the rotation active periods', '10:00', '19:00'
        end

        context 'new timezone has non-whole-hour change' do
          let(:new_timezone) { 'Asia/Kolkata' }

          it_behaves_like 'updates the rotation active periods', '13:30', '22:30'
        end

        context 'new timezone but same offset' do
          let(:new_timezone) { 'Europe/London' }

          it 'updates the timezone' do
            expect { execute }.to change { oncall_schedule.reload.timezone }.to(new_timezone)
          end

          it 'does not update the active period times' do
            expect { execute }.to not_change { time_from_time_column(oncall_rotation.reload.active_period_start) }
             .and not_change { time_from_time_column(oncall_rotation.active_period_end) }
          end
        end

        context 'timezone is not changed' do
          before do
            params.delete(:timezone)
          end

          it 'does not update rotations' do
            expect { execute }.to not_change { oncall_rotation.updated_at }
          end
        end

        context 'error updating' do
          before do
            allow_next_instance_of(IncidentManagement::OncallRotations::EditService) do |edit_service|
              allow(edit_service).to receive(:execute).and_return(double(error?: true, message: 'Test something went wrong'))
            end
          end

          it_behaves_like 'error response', 'Test something went wrong'
        end
      end

      def time_from_time_column(attribute)
        attribute.strftime('%H:%M')
      end
    end
  end
end
