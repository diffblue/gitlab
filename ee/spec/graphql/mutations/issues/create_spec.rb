# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::Create do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:cadence1) { create(:iterations_cadence, group: group) }
  let_it_be(:current_iteration) { create(:iteration, iterations_cadence: cadence1, start_date: 2.days.ago, due_date: 5.days.from_now) }
  let_it_be(:user) { create(:user) }
  let_it_be(:assignee1) { create(:user) }
  let_it_be(:assignee2) { create(:user) }

  let(:expected_attributes) do
    {
      title: 'new title',
      description: 'new description',
      confidential: true,
      due_date: Date.tomorrow,
      discussion_locked: true,
      weight: 10
    }
  end

  let(:inputs) do
    {
      project_path: project.full_path,
      assignee_ids: [assignee1.to_global_id, assignee2.to_global_id],
      health_status: Issue.health_statuses[:at_risk]
    }
  end

  let(:mutation_params) do
    inputs.merge(expected_attributes).merge(additional_attributes)
  end

  let(:additional_attributes) { {} }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:mutated_issue) { resolved_mutation[:issue] }

  before_all do
    project.add_guest(assignee1)
    project.add_guest(assignee2)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_issue) }

  describe '#resolve' do
    before do
      stub_licensed_features(issuable_health_status: true)
      stub_spam_services
    end

    subject(:resolved_mutation) { mutation.resolve(**mutation_params) }

    context 'when user can create issues' do
      before_all do
        group.add_developer(user)
      end

      context 'when iterations are available' do
        let_it_be(:past_iteration) { create(:iteration, iterations_cadence: cadence1, start_date: 9.days.ago, due_date: 3.days.ago) }
        let_it_be(:future_iteration) { create(:iteration, iterations_cadence: cadence1, start_date: 6.days.from_now, due_date: 9.days.from_now) }

        before do
          stub_licensed_features(iterations: true)
        end

        context 'when iteration_id is provided' do
          let(:additional_attributes) { { iteration_id: past_iteration.to_global_id } }

          it 'is successful, and assigns the current iteration to the issue' do
            expect(resolved_mutation[:errors]).to be_empty
            expect(mutated_issue).to have_attributes(iteration: past_iteration)
          end

          context 'when iteration_wildcard_id is provided' do
            let(:additional_attributes) { { iteration_id: past_iteration.to_global_id, iteration_wildcard_id: 'CURRENT', iteration_cadence_id: cadence1.to_global_id } }

            it 'raises a mutually exclusive argument error' do
              expect { resolved_mutation }.to raise_error(
                ::Gitlab::Graphql::Errors::ArgumentError,
                'Incompatible arguments: iterationId, iterationWildcardId.'
              )
            end
          end
        end

        context 'when iteration_wildcard_id is CURRENT' do
          let(:additional_attributes) { { iteration_wildcard_id: 'CURRENT' } }

          context 'when iteration_cadence_id is provided' do
            let(:additional_attributes) { { iteration_wildcard_id: 'CURRENT', iteration_cadence_id: cadence1.to_global_id } }

            it 'is successful, and assigns the current iteration to the issue' do
              expect(resolved_mutation[:errors]).to be_empty
              expect(mutated_issue).to have_attributes(iteration: current_iteration)
            end
          end

          context 'when iteration_cadence_id is not provided' do
            it 'always requires iteration cadence id when wildcard is provided' do
              expect { resolved_mutation }.to raise_error(
                ::Gitlab::Graphql::Errors::ArgumentError,
                'iterationCadenceId is required when iterationWildcardId is provided.'
              )
            end
          end
        end
      end

      context 'when iterations are not available' do
        before do
          stub_licensed_features(iterations: false)
        end

        context 'when iteration_wildcard_id is provided' do
          let(:additional_attributes) { { iteration_wildcard_id: 'CURRENT' } }

          it 'is successful, but it does not add the iteration' do
            expect(resolved_mutation[:errors]).to be_empty
            expect(mutated_issue).to have_attributes(iteration: nil)
          end
        end

        context 'when iteration_id is provided' do
          let(:additional_attributes) { { iteration_id: current_iteration.to_global_id } }

          it 'is successful, but it does not add the iteration' do
            expect(resolved_mutation[:errors]).to be_empty
            expect(mutated_issue).to have_attributes(iteration: nil)
          end
        end
      end

      it 'creates issue with correct EE values' do
        expect(mutated_issue).to have_attributes(expected_attributes)
        expect(mutated_issue.assignees.pluck(:id)).to eq([assignee1.id, assignee2.id])
        expect(mutated_issue.health_status).to eq('at_risk')
      end

      context 'when the epic_id parameter is passed' do
        let(:epic) { create(:epic, group: group) }

        let(:mutation_params) do
          inputs.merge(expected_attributes).merge(epic_id: epic.to_global_id)
        end

        context 'epics are available' do
          before do
            stub_licensed_features(epics: true)
          end

          it 'is successful, and assigns the issue to the epic' do
            expect(resolved_mutation[:errors]).to be_empty
            expect(mutated_issue).to have_attributes(epic: epic)
          end

          context 'the project is not in a group' do
            let(:project) { create(:project) }

            it 'is successful, but it does not add the epic' do
              project.add_developer(user)

              expect(resolved_mutation[:errors]).to be_empty
              expect(mutated_issue).not_to have_attributes(epic: epic)
            end
          end
        end

        context 'epics are unavailable' do
          it 'is unsuccessful' do
            expect(resolved_mutation[:errors]).to contain_exactly(/^Couldn't find Epic/)
          end

          it 'does not create an issue' do
            expect(mutated_issue).to be_nil
          end
        end
      end
    end
  end
end
