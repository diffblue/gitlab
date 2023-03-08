# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::DestroyService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let!(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }
  let!(:oncall_rotation) { create(:incident_management_oncall_rotation, schedule: oncall_schedule) }
  let(:current_user) { user_with_permissions }
  let(:params) { {} }
  let(:service) { described_class.new(oncall_rotation, current_user) }

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

      it_behaves_like 'error response', 'You have insufficient permissions to remove an on-call rotation from this project'
    end

    context 'when the current_user does not have permissions to remove on-call rotations' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to remove an on-call rotation from this project'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call rotations'
    end

    context 'when an error occurs during removal' do
      before do
        allow(oncall_rotation).to receive(:destroy).and_return(false)
        oncall_rotation.errors.add(:name, 'cannot be removed')
      end

      it_behaves_like 'error response', 'Name cannot be removed'
    end

    it 'successfully deletes and returns the rotation' do
      expect(execute).to be_success

      oncall_rotation_result = execute.payload[:oncall_rotation]
      expect(oncall_rotation_result).to be_a(::IncidentManagement::OncallRotation)
      expect(oncall_rotation_result.name).to eq(oncall_rotation.name)
      expect { oncall_rotation_result.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
