# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::EscalationPolicy::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }

  let(:args) do
    {
      project_path: project.full_path,
      name: 'Escalation policy name',
      description: 'Escalation policy description',
      rules: [
        {
          oncall_schedule_iid: oncall_schedule.iid,
          elapsed_time_seconds: 300,
          status: ::IncidentManagement::EscalationRule.statuses[:acknowledged]
        },
        {
          username: current_user&.username,
          elapsed_time_seconds: 600,
          status: ::IncidentManagement::EscalationRule.statuses[:resolved]
        }
      ]
    }
  end

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(project_path: project.full_path, **args) }

    shared_examples 'returns a GraphQL error' do |error|
      it { is_expected.to match(escalation_policy: nil, errors: [error]) }
    end

    shared_examples 'raises a resource not available error' do |error|
      specify do
        expect { resolve }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          error || Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    before do
      project.add_maintainer(current_user)
    end

    context 'project does not have feature' do
      before do
        stub_licensed_features(oncall_schedules: true)
      end

      it_behaves_like 'raises a resource not available error', 'Escalation policies are not supported for this project'
    end

    context 'project has feature' do
      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true)
      end

      context 'user has access to project' do
        it 'returns the escalation policy with no errors' do
          expect(resolve).to match(
            escalation_policy: ::IncidentManagement::EscalationPolicy.last!,
            errors: be_empty
          )

          rules = resolve[:escalation_policy].rules

          expect(rules.size).to eq(2)
          expect(rules).to match_array(
            [
              have_attributes(oncall_schedule_id: oncall_schedule.id, user: nil, elapsed_time_seconds: 300, status: 'acknowledged'),
              have_attributes(oncall_schedule_id: nil, user: current_user, elapsed_time_seconds: 600, status: 'resolved')
            ])
        end

        context 'rules are missing' do
          before do
            args[:rules] = []
          end

          it_behaves_like 'returns a GraphQL error', 'Escalation policies must have at least one rule'
        end

        context 'schedule that does not belong to the project' do
          let!(:other_schedule) {  create(:incident_management_oncall_schedule, iid: 2) }

          before do
            args[:rules][0][:oncall_schedule_iid] = other_schedule.iid
          end

          it_behaves_like 'raises a resource not available error'

          context 'user does not have permission for project' do
            before do
              project.add_reporter(current_user)
            end

            it_behaves_like 'raises a resource not available error'
          end
        end

        context 'user for rule does not exist' do
          before do
            args[:rules][1][:username] = 'junk-username'
          end

          it_behaves_like 'raises a resource not available error'
        end
      end

      context 'user does not have permission for project' do
        before do
          project.add_reporter(current_user)
        end

        it_behaves_like 'raises a resource not available error'
      end
    end

    context 'invalid project path' do
      before do
        args[:project_path] = 'something/incorrect'
      end

      it_behaves_like 'raises a resource not available error'
    end
  end

  private

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
