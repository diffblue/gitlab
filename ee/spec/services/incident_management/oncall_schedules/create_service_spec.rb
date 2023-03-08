# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallSchedules::CreateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let(:current_user) { user_with_permissions }
  let(:params) { { name: 'On-call schedule', description: 'On-call schedule description', timezone: 'Europe/Berlin' } }
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

    subject(:execute) { service.execute }

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to create an on-call schedule for this project'
    end

    context 'when the current_user does not have permissions to create on-call schedules' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to create an on-call schedule for this project'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call schedules'
    end

    context 'when an on-call schedule already exists' do
      let!(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project, name: 'On-call schedule') }

      it_behaves_like 'error response', 'Name has already been taken'
    end

    context 'with valid params' do
      it 'successfully creates an on-call schedule' do
        expect(execute).to be_success

        oncall_schedule = execute.payload[:oncall_schedule]
        expect(oncall_schedule).to be_a(::IncidentManagement::OncallSchedule)
        expect(oncall_schedule.name).to eq('On-call schedule')
        expect(oncall_schedule.description).to eq('On-call schedule description')
        expect(oncall_schedule.timezone).to eq('Europe/Berlin')
      end
    end
  end
end
