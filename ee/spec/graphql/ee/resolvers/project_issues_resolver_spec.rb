# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectIssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group, skip_disk_validation: true) }

  context "with a project" do
    describe '#resolve' do
      let_it_be(:epic1) { create :epic, group: group }
      let_it_be(:epic2) { create :epic, group: group, parent: epic1 }

      let_it_be(:cadence) { create(:iterations_cadence, group: group) }
      let_it_be(:iteration1) { create(:iteration, iterations_cadence: cadence, start_date: 2.weeks.ago, due_date: 1.week.ago) }
      let_it_be(:current_iteration) { create(:iteration, iterations_cadence: cadence, start_date: Date.yesterday, due_date: 1.day.from_now) }

      let_it_be(:issue1) { create :issue, project: project, epic: epic1, iteration: iteration1, blocking_issues_count: 2, health_status: 'at_risk' }
      let_it_be(:issue2) { create :issue, project: project, epic: epic2, weight: 1, blocking_issues_count: 2 }
      let_it_be(:issue3) { create :issue, project: project, weight: 3, iteration: current_iteration, blocking_issues_count: 4, health_status: 'on_track' }
      let_it_be(:issue4) { create :issue, :published, project: project, health_status: 'needs_attention' }

      before do
        project.add_developer(current_user)
      end

      describe 'sorting' do
        context 'when sorting by weight' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :weight_asc).to_a).to eq [issue2, issue3, issue4, issue1]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :weight_desc).to_a).to eq [issue3, issue2, issue4, issue1]
          end
        end

        context 'when sorting by published' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :published_asc).to_a).to eq [issue3, issue2, issue1, issue4]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :published_desc).to_a).to eq [issue4, issue3, issue2, issue1]
          end
        end

        context 'when sorting by sla due at' do
          let_it_be(:sla_due_first) { create(:incident, project: project) }
          let_it_be(:sla_due_last)  { create(:incident, project: project) }

          before_all do
            create(:issuable_sla, :exceeded, issue: sla_due_first)
            create(:issuable_sla, issue: sla_due_last)
          end

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :sla_due_at_asc).to_a).to eq [sla_due_first, sla_due_last]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :sla_due_at_desc).to_a).to eq [sla_due_last, sla_due_first]
          end
        end

        context 'when sorting by blocking issues count (ties broken by id in desc order)' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :blocking_issues_asc).to_a).to eq [issue4, issue2, issue1, issue3]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :blocking_issues_desc).to_a).to eq [issue3, issue2, issue1, issue4]
          end
        end

        context 'when sorting by health status' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :health_status_asc).to_a).to eq [issue3, issue4, issue1, issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :health_status_desc).to_a).to eq [issue1, issue4, issue3, issue2]
          end
        end
      end

      describe 'filtering by iteration' do
        let_it_be(:iteration1) { create(:iteration, iterations_cadence: cadence, start_date: 4.weeks.ago, due_date: 3.weeks.ago) }
        let_it_be(:iteration2) { create(:iteration, iterations_cadence: cadence, start_date: 6.weeks.ago, due_date: 5.weeks.ago) }
        let_it_be(:issue_with_iteration1) { create(:issue, project: project, iteration: iteration1) }
        let_it_be(:issue_with_iteration2) { create(:issue, project: project, iteration: iteration2) }
        let_it_be(:issue_without_iteration) { create(:issue, project: project) }

        it 'returns issues with iteration using raw id' do
          expect(resolve_issues(iteration_id: [iteration1.id])).to contain_exactly(issue_with_iteration1)
        end

        it 'returns issues with iteration using global id' do
          expect(resolve_issues(iteration_id: [iteration1.to_global_id])).to contain_exactly(issue_with_iteration1)
        end

        it 'returns issues with list iterations using global id' do
          expect(resolve_issues(iteration_id: [iteration1.to_global_id, iteration2.to_global_id]))
            .to contain_exactly(issue_with_iteration1, issue_with_iteration2)
        end

        it 'returns issues with list iterations using a mix' do
          expect(resolve_issues(iteration_id: [iteration1.id, iteration2.to_global_id]))
            .to contain_exactly(issue_with_iteration1, issue_with_iteration2)
        end
      end

      describe 'filtering by iteration wildcard' do
        it 'returns issues with current iteration' do
          expect(resolve_issues(iteration_wildcard_id: 'CURRENT')).to contain_exactly(issue3)
        end

        it 'returns issues with any iteration' do
          expect(resolve_issues(iteration_wildcard_id: 'ANY')).to contain_exactly(issue1, issue3)
        end

        it 'returns issues with no iteration' do
          expect(resolve_issues(iteration_wildcard_id: 'NONE')).to contain_exactly(issue2, issue4)
        end

        it 'generates mutually exclusive filter error when wildcard and list are provided' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'only one of [iterationId, iterationWildcardId] arguments is allowed at the same time.') do
            resolve_issues(iteration_id: [iteration1.to_global_id], iteration_wildcard_id: 'CURRENT')
          end
        end
      end

      describe 'filter by epic' do
        it 'returns issues without epic when epic_id is "none"' do
          expect(resolve_issues(epic_id: 'none')).to contain_exactly(issue4, issue3)
        end

        it 'returns issues with any epic when epic_id is "any"' do
          expect(resolve_issues(epic_id: 'any')).to contain_exactly(issue1, issue2)
        end

        it 'returns issues with any epic when epic_id is specific' do
          expect(resolve_issues(epic_id: epic1.id.to_s)).to contain_exactly(issue1)
        end

        it 'includes issues associated with subepics when specified' do
          expect(resolve_issues(epic_id: epic1.id.to_s, include_subepics: true)).to contain_exactly(issue1, issue2)
        end
      end

      describe 'filter by weight' do
        context 'when filtering by any weight' do
          it 'only returns issues that have a weight assigned' do
            expect(resolve_issues(weight: 'any')).to contain_exactly(issue2, issue3)
          end
        end

        context 'when filtering by no weight' do
          it 'only returns issues that have no weight assigned' do
            expect(resolve_issues(weight: 'none')).to contain_exactly(issue1, issue4)
          end
        end

        context 'when filtering by specific weight' do
          it 'only returns issues that have the specified weight assigned' do
            expect(resolve_issues(weight: '3')).to contain_exactly(issue3)
          end
        end
      end

      describe 'filter by health status' do
        let(:at_risk) { Issue.health_statuses[:at_risk] }

        context 'when filtering by specific health status' do
          it 'only returns issues that have the specified health status assigned' do
            expect(resolve_issues(health_status_filter: at_risk)).to contain_exactly(issue1)
          end
        end

        context 'when filtering by any health status' do
          specify { expect(resolve_issues(health_status_filter: 'any')).to contain_exactly(issue1, issue3, issue4) }
        end

        context 'when filtering by no health status' do
          specify { expect(resolve_issues(health_status_filter: 'none')).to contain_exactly(issue2) }
        end

        context 'when health_status and health_status_filter arguments are both given' do
          it 'overwrites health_status with value of health_status_filter' do
            expect(resolve_issues(health_status_filter: 'none', health_status: at_risk)).to contain_exactly(issue2)
          end
        end
      end

      describe 'filtering by negated params' do
        describe 'filter by negated epic' do
          it 'returns issues without the specified epic_id' do
            expect(resolve_issues(not: { epic_id: epic2.id.to_s })).to contain_exactly(issue1, issue3, issue4)
          end
        end

        describe 'filtering by negated weight' do
          it 'only returns issues that do not have the specified weight assigned' do
            expect(resolve_issues(not: { weight: '3' })).to contain_exactly(issue1, issue2, issue4)
          end
        end

        describe 'filtering by negated iteration' do
          it 'returns issues without iteration using RAW id' do
            expect(resolve_issues(not: { iteration_id: [iteration1.id.to_s] })).to contain_exactly(issue2, issue3, issue4)
          end

          it 'works with global IDs' do
            expect(resolve_issues(not: { iteration_id: [iteration1.to_global_id] })).to contain_exactly(issue2, issue3, issue4)
          end

          it 'generates a mutually exclusive filter error when wildcard and list are provided' do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'only one of [iterationId, iterationWildcardId] arguments is allowed at the same time.') do
              resolve_issues(not: { iteration_id: [iteration1.to_global_id], iteration_wildcard_id: 'CURRENT' })
            end
          end
        end

        describe 'filtering by negated iteration wildcard' do
          it 'returns issues not in the current iteration' do
            expect(resolve_issues(not: { iteration_wildcard_id: 'CURRENT' })).to contain_exactly(issue1, issue2, issue4)
          end
        end

        describe "filtering by negated health_status" do
          let(:at_risk) { Issue.health_statuses[:at_risk] }

          it "only returns issues that do not have the specified health_status assigned" do
            expect(resolve_issues(not: { health_status_filter: at_risk })).to contain_exactly(issue2, issue3, issue4)
          end
        end
      end
    end
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context, arg_style: :internal)
  end
end
