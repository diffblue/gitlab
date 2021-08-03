# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::EscalationPolicy::Update do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }
  let_it_be_with_reload(:escalation_policy) { create(:incident_management_escalation_policy, project: project, rule_count: 2) }
  let_it_be_with_reload(:escalation_rules) { escalation_policy.rules }
  let_it_be_with_reload(:first_rule) { escalation_rules.first }

  let(:args) do
    {
      id: policy_id,
      name: name,
      rules: rule_args,
      description: 'Updated escalation policy description'
    }
  end

  let(:policy_id) { GitlabSchema.id_from_object(escalation_policy).to_s }
  let(:name) { 'Updated escalation policy name' }
  let(:rule_args) { nil }
  let(:expected_rules) { escalation_rules }

  before do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)

    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  describe '#resolve' do
    let(:current_user) { maintainer }

    subject(:resolve) { mutation_for(current_user).resolve(**args) }

    # Requires `expected_rules` to be defined
    shared_examples 'successful update with no errors' do
      it 'returns the updated escalation policy' do
        expect(resolve).to match(
          escalation_policy: escalation_policy,
          errors: be_empty
        )

        expect(resolve[:escalation_policy]).to have_attributes(escalation_policy.reload.attributes)
        expect(escalation_policy).to have_attributes(args.slice(:name, :description))
        expect(escalation_policy.active_rules).to match_array(expected_rules)
      end
    end

    shared_examples 'failed update with a top-level access error' do |error|
      specify do
        expect { resolve }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          error || Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when the policy cannot be found' do
      let(:policy_id) { Gitlab::GlobalId.build(nil, model_name: ::IncidentManagement::EscalationPolicy.name, id: non_existing_record_id).to_s }

      it_behaves_like 'failed update with a top-level access error'
    end

    context 'when project does not have feature' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: false)
      end

      it_behaves_like 'failed update with a top-level access error', 'Escalation policies are not supported for this project'
    end

    context 'when user does not have permissions to update the policy' do
      let(:current_user) { reporter }

      it_behaves_like 'failed update with a top-level access error'
    end

    context 'when there is an error in updating' do
      let(:name) { 'name' * 100 }

      it 'returns errors in the body of the response' do
        expect(resolve).to eq(
          escalation_policy: nil,
          errors: ['Name is too long (maximum is 72 characters)']
        )
      end
    end

    context 'when rules are excluded' do
      let(:rule_args) { nil }

      it_behaves_like 'successful update with no errors'
    end

    context 'when rules are included but empty' do
      let(:rule_args) { [] }

      it 'returns errors in the body of the response' do
        expect(resolve).to eq(
          escalation_policy: nil,
          errors: ['Escalation policies must have at least one rule']
        )
      end
    end

    context 'with rule updates' do
      let(:oncall_schedule_iid) { oncall_schedule.iid }
      let(:username) { reporter.username }
      let(:rule_args) do
        [
          {
            oncall_schedule_iid: first_rule.oncall_schedule.iid,
            elapsed_time_seconds: first_rule.elapsed_time_seconds,
            status: first_rule.status.to_sym
          },
          {
            oncall_schedule_iid: oncall_schedule_iid,
            username: nil,
            elapsed_time_seconds: 800,
            status: :acknowledged
          },
          {
            oncall_schedule_iid: nil,
            username: username,
            elapsed_time_seconds: 800,
            status: :acknowledged
          }
        ]
      end

      let(:expected_rules) do
        [
          first_rule,
          have_attributes(oncall_schedule_id: oncall_schedule.id, user: nil, elapsed_time_seconds: 800, status: 'acknowledged'),
          have_attributes(oncall_schedule_id: nil, user: reporter, elapsed_time_seconds: 800, status: 'acknowledged')
        ]
      end

      it_behaves_like 'successful update with no errors'

      context 'when schedule does not exist' do
        let(:oncall_schedule_iid) { non_existing_record_iid }

        it_behaves_like 'failed update with a top-level access error'

        context 'the user does not have permission to update policies regardless' do
          let(:current_user) { reporter }

          it_behaves_like 'failed update with a top-level access error'
        end
      end

      context "when rule's user does not exist" do
        let(:username) { 'invalid-username' }

        it_behaves_like 'failed update with a top-level access error'
      end
    end
  end

  private

  def mutation_for(user)
    described_class.new(object: nil, context: { current_user: user }, field: nil)
  end
end
