# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicies::DestroyService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_refind(:project) { create(:project) }

  let!(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }
  let(:current_user) { user_with_permissions }
  let(:params) { {} }
  let(:service) { described_class.new(escalation_policy, current_user) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  before_all do
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

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when the current_user does not have permissions to remove escalation policies' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when license is not enabled' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: false)
      end

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when an error occurs during removal' do
      before do
        allow(escalation_policy).to receive(:destroy).and_return(false)
        escalation_policy.errors.add(:name, 'cannot be removed')
      end

      it_behaves_like 'error response', 'Name cannot be removed'
    end

    it 'successfully returns the escalation policy' do
      expect(execute).to be_success

      escalation_policy_result = execute.payload[:escalation_policy]
      expect(escalation_policy_result).to be_a(::IncidentManagement::EscalationPolicy)
      expect(escalation_policy_result.name).to eq(escalation_policy.name)
      expect(escalation_policy_result.description).to eq(escalation_policy.description)
    end
  end
end
