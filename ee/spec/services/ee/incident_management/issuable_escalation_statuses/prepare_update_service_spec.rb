# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::PrepareUpdateService,
  feature_category: :incident_management do
  let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status, :triggered) }
  let_it_be(:policy) { create(:incident_management_escalation_policy, project: escalation_status.issue.project) }
  let_it_be(:user_with_permissions) { create(:user) }

  let(:current_user) { user_with_permissions }
  let(:issue) { escalation_status.issue }
  let(:status) { :acknowledged }
  let(:params) { { status: status, policy: policy } }
  let(:service) { described_class.new(issue, current_user, params) }

  subject(:result) { service.execute }

  before do
    issue.project.add_developer(user_with_permissions)
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  shared_examples 'successful response' do
    it 'returns valid parameters which can be used to update the issue', :freeze_time do
      expect(result).to be_success
      expect(result.payload).to eq(payload)
    end
  end

  shared_examples 'successful response without policy params' do
    include_examples 'successful response' do
      let(:payload) { { escalation_status: { status_event: :acknowledge } } }
    end
  end

  it_behaves_like 'successful response' do
    let(:payload) do
      {
        escalation_status: {
          policy: policy,
          escalations_started_at: Time.current
        }
      }
    end
  end

  context 'when policy is unchanged' do
    let(:params) { { policy: nil } }

    it_behaves_like 'successful response' do
      let(:payload) { { escalation_status: {} } }
    end
  end

  context 'when escalation policies feature is unavailable' do
    before do
      stub_licensed_features(oncall_schedules: false, escalation_policies: false)
    end

    it_behaves_like 'successful response without policy params'
  end

  context 'when issue is associated with an alert' do
    let!(:alert) { create(:alert_management_alert, issue: issue, project: issue.project) }

    it_behaves_like 'successful response' do
      let(:payload) do
        {
          escalation_status: {
            policy: policy,
            escalations_started_at: Time.current
          }
        }
      end
    end
  end

  context 'when provided policy is in a different project' do
    let(:issue) { create(:incident) }

    before do
      create(:incident_management_issuable_escalation_status, issue: issue)
    end

    it 'returns an error response' do
      expect(result).to be_error
      expect(result.message).to eq('Invalid value was provided for parameters: policy')
    end
  end

  context 'when the escalation status is already associated with a policy' do
    before do
      escalation_status.update!(policy_id: policy.id, escalations_started_at: Time.current)
    end

    context 'when policy is unchanged' do
      it_behaves_like 'successful response without policy params'
    end

    context 'when policy is excluded' do
      let(:params) { { status: status } }

      it_behaves_like 'successful response without policy params'
    end

    context 'when policy is nil' do
      let(:params) { { status: status, policy: nil } }

      it_behaves_like 'successful response' do
        let(:payload) do
          {
            escalation_status: {
              status_event: :acknowledge,
              policy: nil,
              escalations_started_at: nil
            }
          }
        end
      end
    end
  end
end
