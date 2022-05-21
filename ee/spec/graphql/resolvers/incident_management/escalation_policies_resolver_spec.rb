# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolvers::IncidentManagement::EscalationPoliciesResolver' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:policy) { create(:incident_management_escalation_policy, project: project, name: 'Target policy') }
  let_it_be(:other_policy) { create(:incident_management_escalation_policy) }
  let_it_be(:described_class) { Resolvers::IncidentManagement::EscalationPoliciesResolver }

  let(:args) { {} }
  let(:resolver) { described_class }

  subject(:resolved_policies) { sync(resolve_escalation_policies(args, current_user: current_user).to_a) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    project.add_reporter(current_user)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::IncidentManagement::EscalationPolicyType.connection_type)
  end

  it 'returns escalation policies' do
    expect(resolved_policies.length).to eq(1)
    expect(resolved_policies.first).to be_a(::IncidentManagement::EscalationPolicy)
    expect(resolved_policies.first).to have_attributes(id: policy.id)
  end

  context 'with name param provided' do
    let(:args) { { name: 'target' } }

    it 'returns escalation policies matching the name search' do
      expect(resolved_policies.length).to eq(1)
      expect(resolved_policies.first).to be_a(::IncidentManagement::EscalationPolicy)
      expect(resolved_policies.first).to have_attributes(id: policy.id)
    end
  end

  context 'when resolving a single item' do
    let(:resolver) { described_class.single }

    subject(:resolved_policy) { sync(resolve_escalation_policies(args, current_user: current_user)) }

    context 'when id given' do
      let(:args) { { id: policy.to_global_id } }

      it 'returns the policy' do
        expect(resolved_policy).to eq(policy)
      end
    end
  end

  context 'when user does not have permissions' do
    let(:another_user) { create(:user) }

    subject(:resolved_policies) { sync(resolve_escalation_policies(args, current_user: another_user).to_a) }

    it 'returns no policies' do
      expect(resolved_policies.length).to eq(0)
    end
  end

  private

  def resolve_escalation_policies(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: project, args: args, ctx: context)
  end
end
