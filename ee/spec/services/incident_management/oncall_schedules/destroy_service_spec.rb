# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallSchedules::DestroyService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let!(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }
  let(:current_user) { user_with_permissions }
  let(:params) { {} }
  let(:service) { described_class.new(project: project, current_user: current_user) }

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

      it_behaves_like 'error response', 'You have insufficient permissions to remove an on-call schedule from this project'
    end

    context 'when the current_user does not have permissions to remove on-call schedules' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to remove an on-call schedule from this project'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call schedules'
    end

    context 'when an error occurs during removal' do
      before do
        allow(oncall_schedule).to receive(:destroy).and_return(false)
        oncall_schedule.errors.add(:name, 'cannot be removed')
      end

      it_behaves_like 'error response', 'Name cannot be removed'
    end

    it 'successfully returns the integration' do
      expect(execute).to be_success

      oncall_schedule_result = execute.payload[:oncall_schedule]
      expect(oncall_schedule_result).to be_a(::IncidentManagement::OncallSchedule)
      expect(oncall_schedule_result.name).to eq(oncall_schedule.name)
      expect(oncall_schedule_result.description).to eq(oncall_schedule.description)
      expect(oncall_schedule_result.timezone).to eq(oncall_schedule.timezone)
    end
  end
end
