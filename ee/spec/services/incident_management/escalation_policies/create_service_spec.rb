# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationPolicies::CreateService, feature_category: :incident_management do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:user) { user_with_permissions }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  before_all do
    project.add_maintainer(user_with_permissions)
  end

  let(:rule_params) do
    [
      {
        oncall_schedule: oncall_schedule,
        elapsed_time_seconds: 60,
        status: :resolved
      }
    ]
  end

  let(:params) { { name: 'Policy', description: 'Description', rules_attributes: rule_params } }
  let(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'error response' do |message|
      it 'does not save the policy and has an informative message' do
        expect { execute }.not_to change(IncidentManagement::EscalationPolicy, :count)
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    context 'when user does not have access' do
      let(:user) { create(:user) }

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'when license is not enabled' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: false)
      end

      it_behaves_like 'error response', 'You have insufficient permissions to configure escalation policies for this project'
    end

    context 'validation errors' do
      context 'validation error in policy' do
        before do
          params[:name] = ''
        end

        it_behaves_like 'error response', "Name can't be blank"
      end

      context 'no rules are given' do
        let(:rule_params) { nil }

        it_behaves_like 'error response', 'Escalation policies must have at least one rule'
      end

      context 'too many rules are given' do
        let(:rule_params) do
          (0..10).map do |idx|
            {
              oncall_schedule: oncall_schedule,
              elapsed_time_seconds: idx,
              status: :acknowledged
            }
          end
        end

        it_behaves_like 'error response', 'Escalation policies may not have more than 10 rules'
      end

      context 'oncall schedule is on the wrong project' do
        before do
          rule_params[0][:oncall_schedule] = create(:incident_management_oncall_schedule)
        end

        it_behaves_like 'error response', 'Schedule-based escalation rules must have a schedule in the same project as the policy'
      end

      context 'user for rule does not have project access' do
        let(:rule_params) do
          [
            {
              user: create(:user),
              elapsed_time_seconds: 60,
              status: :resolved
            }
          ]
        end

        it_behaves_like 'error response', 'User-based escalation rules must have a user with access to the project'
      end

      context 'project has an existing escalation policy' do
        before do
          create(:incident_management_escalation_policy, project: project)
        end

        it_behaves_like 'error response', "Project can only have one escalation policy"
      end
    end

    context 'valid params' do
      it 'creates the policy and rules' do
        expect(execute).to be_success

        policy = execute.payload[:escalation_policy]
        expect(policy).to be_a(::IncidentManagement::EscalationPolicy)
        expect(policy.rules.length).to eq(1)
        expect(policy.rules.first).to have_attributes(
          oncall_schedule: oncall_schedule,
          user: nil,
          elapsed_time_seconds: 60,
          status: 'resolved'
        )
      end

      context 'for a user-based escalation rule' do
        let(:rule_params) do
          [
            {
              user: user_with_permissions,
              elapsed_time_seconds: 60,
              status: :resolved
            }
          ]
        end

        it 'creates the policy and rules' do
          expect(execute).to be_success

          policy = execute.payload[:escalation_policy]
          expect(policy).to be_a(::IncidentManagement::EscalationPolicy)
          expect(policy.rules.length).to eq(1)
          expect(policy.rules.first).to have_attributes(
            oncall_schedule: nil,
            user: user_with_permissions,
            elapsed_time_seconds: 60,
            status: 'resolved'
          )
        end
      end
    end
  end
end
