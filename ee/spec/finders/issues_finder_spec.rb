# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder do
  describe '#execute' do
    include_context 'IssuesFinder context'
    include_context 'IssuesFinder#execute context'

    context 'scope: all' do
      let(:scope) { 'all' }

      describe 'filter by scoped label wildcard' do
        let_it_be(:search_user) { create(:user) }
        let(:base_params) { { project_id: project3.id } }

        let_it_be(:group_devops_plan_label) { create(:group_label, group: group, title: 'devops::plan') }
        let_it_be(:group_wfe_in_dev_label) { create(:group_label, group: group, title: 'workflow::frontend::in dev') }
        let_it_be(:group_wfe_in_review_label) { create(:group_label, group: group, title: 'workflow::frontend::in review') }
        let_it_be(:subgroup_devops_create_label) { create(:group_label, group: subgroup, title: 'devops::create') }
        let_it_be(:project_wbe_in_dev_label) { create(:label, project: project3, title: 'workflow::backend::in dev') }
        let_it_be(:project_label) { create(:label, project: project3) }

        let_it_be(:devops_plan_be_in_dev_issue) { create(:labeled_issue, project: project3, labels: [group_devops_plan_label, project_wbe_in_dev_label]) }
        let_it_be(:project_fe_in_dev_issue) { create(:labeled_issue, project: project3, labels: [project_label, group_wfe_in_dev_label]) }
        let_it_be(:devops_create_issue) { create(:labeled_issue, project: project3, labels: [subgroup_devops_create_label]) }
        let_it_be(:be_in_dev_issue) { create(:labeled_issue, project: project3, labels: [project_wbe_in_dev_label]) }
        let_it_be(:project_fe_in_review_issue) { create(:labeled_issue, project: project3, labels: [project_label, group_wfe_in_review_label]) }

        before_all do
          project3.add_developer(search_user)
        end

        before do
          stub_licensed_features(scoped_labels: true)
        end

        context 'when scoped labels are unavailable' do
          let(:params) { base_params.merge(label_name: 'devops::*') }

          before do
            stub_licensed_features(scoped_labels: false)
          end

          it 'does not return any results' do
            expect(items).to be_empty
          end
        end

        context 'when project scope is not given' do
          let(:params) { { label_name: 'devops::*' } }

          it 'does not return any results' do
            expect(items).to be_empty
          end
        end

        context 'with a single wildcard filter' do
          let(:params) { base_params.merge(label_name: 'devops::*') }

          it 'returns issues that have labels that match the wildcard' do
            expect(items).to contain_exactly(devops_plan_be_in_dev_issue, devops_create_issue)
          end
        end

        context 'with multiple wildcard filters' do
          let(:params) { base_params.merge(label_name: ['devops::*', 'workflow::backend::*']) }

          it 'returns issues that have labels that match both wildcards' do
            expect(items).to contain_exactly(devops_plan_be_in_dev_issue)
          end
        end

        context 'combined with a regular label filter' do
          let(:params) { base_params.merge(label_name: [project_label.name, 'workflow::frontend::*']) }

          it 'returns issues that have labels that match the wildcard and the regular label' do
            expect(items).to contain_exactly(project_fe_in_dev_issue, project_fe_in_review_issue)
          end
        end

        context 'with nested prefix' do
          let(:params) { base_params.merge(label_name: 'workflow::*') }

          it 'returns issues that have labels that match the prefix' do
            expect(items).to contain_exactly(devops_plan_be_in_dev_issue, be_in_dev_issue, project_fe_in_dev_issue, project_fe_in_review_issue)
          end
        end

        context 'with overlapping prefixes' do
          let(:params) { base_params.merge(label_name: ['workflow::*', 'workflow::backend::*']) }

          it 'returns issues that have labels that match both prefixes' do
            expect(items).to contain_exactly(devops_plan_be_in_dev_issue, be_in_dev_issue)
          end
        end

        context 'using NOT' do
          let(:params) { base_params.merge(not: { label_name: 'devops::*' }) }

          it 'returns issues that do not have labels that match the wildcard' do
            expect(items).to contain_exactly(item4, project_fe_in_dev_issue, project_fe_in_review_issue, be_in_dev_issue)
          end
        end
      end

      describe 'filter by weight' do
        let_it_be(:issue_with_weight_1) { create(:issue, project: project3, weight: 1) }
        let_it_be(:issue_with_weight_42) { create(:issue, project: project3, weight: 42) }

        context 'filter issues with no weight' do
          let(:params) { { weight: Issue::WEIGHT_NONE } }

          it 'returns all issues' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5)
          end
        end

        context 'filter issues with any weight' do
          let(:params) { { weight: Issue::WEIGHT_ANY } }

          it 'returns all issues' do
            expect(items).to contain_exactly(issue_with_weight_1, issue_with_weight_42)
          end
        end

        context 'filter issues with a specific weight' do
          let(:params) { { weight: 42 } }

          it 'returns all issues' do
            expect(items).to contain_exactly(issue_with_weight_42)
          end
        end

        context 'filer issues by negated weight' do
          let(:params) { { not: { weight: 1 } } }

          it 'filters out issues with the specified weight' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, issue_with_weight_42)
          end
        end
      end

      context 'filtering by assignee IDs' do
        let_it_be(:user3) { create(:user) }

        let(:params) { { assignee_ids: [user2.id, user3.id] } }

        before do
          project2.add_developer(user3)

          item3.assignees = [user2, user3]
        end

        it 'returns issues assigned to those users' do
          expect(items).to contain_exactly(item3)
        end
      end

      context 'filter by username' do
        let_it_be(:user3) { create(:user) }

        let(:issuables) { items }

        before do
          project2.add_developer(user3)
          item2.assignees = [user, user2]
          item3.assignees = [user2, user3]
        end

        it_behaves_like 'assignee username filter' do
          let(:params) { { assignee_username: [user2.username, user3.username] } }
          let(:expected_issuables) { [item3] }
        end

        it_behaves_like 'assignee NOT username filter' do
          let(:params) { { not: { assignee_username: [user.username, user2.username] } } }
          let(:expected_issuables) { [item4] }
        end
      end

      context 'filter by epic' do
        let_it_be(:epic_1) { create(:epic, group: group) }
        let_it_be(:epic_2) { create(:epic, group: group) }
        let_it_be(:sub_epic) { create(:epic, group: group, parent: epic_1) }

        let_it_be(:issue_1) { create(:issue, project: project1, epic: epic_1) }
        let_it_be(:issue_2) { create(:issue, project: project1, epic: epic_2) }
        let_it_be(:issue_subepic) { create(:issue, project: project1, epic: sub_epic) }

        context 'filter issues with no epic' do
          let(:params) { { epic_id: ::IssuableFinder::Params::FILTER_NONE } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5)
          end
        end

        context 'filter issues by epic' do
          let(:params) { { epic_id: epic_1.id } }

          context 'when include_subepics param is not included' do
            it 'returns all issues in the epic, subepic issues excluded' do
              expect(items).to contain_exactly(issue_1)
            end
          end

          context 'when include_subepics param is set to true' do
            before do
              params[:include_subepics] = true
            end

            it 'returns all issues in the epic including subepic issues' do
              expect(items).to contain_exactly(issue_1, issue_subepic)
            end
          end
        end

        context 'filter issues with any epic' do
          let(:params) { { epic_id: ::IssuableFinder::Params::FILTER_ANY } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(issue_1, issue_2, issue_subepic)
          end
        end

        context 'filter issues not in the epic' do
          let(:params) { { not: { epic_id: epic_1.id } } }

          it 'returns issues not assigned to the epic' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, issue_2, issue_subepic)
          end
        end
      end

      context 'filter by iteration' do
        let_it_be(:cadence) { create(:iterations_cadence, group: group) }
        let_it_be(:iteration_1) { create(:iteration, :with_title, iterations_cadence: cadence, start_date: 2.days.from_now, due_date: 3.days.from_now) }
        let_it_be(:iteration_2) { create(:iteration, iterations_cadence: cadence, start_date: 4.days.from_now, due_date: 5.days.from_now) }

        let_it_be(:iteration_1_issue) { create(:issue, project: project1, iteration: iteration_1) }
        let_it_be(:iteration_2_issue) { create(:issue, project: project1, iteration: iteration_2) }

        context 'filter issues with no iteration' do
          let(:params) { { iteration_id: ::IssuableFinder::Params::FILTER_NONE } }

          it 'returns all issues without iterations' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5)
          end
        end

        context 'filter issues with any iteration' do
          let(:params) { { iteration_id: ::IssuableFinder::Params::FILTER_ANY } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(iteration_1_issue, iteration_2_issue)
          end
        end

        context 'filter issues by current iteration' do
          let(:current_iteration) { nil }
          let(:params) { { group_id: group, iteration_id: ::Iteration::Predefined::Current.title } }
          let!(:current_iteration_issue) { create(:issue, project: project1, iteration: current_iteration) }

          context 'when no current iteration is found' do
            it 'returns no issues' do
              expect(items).to be_empty
            end
          end

          context 'when current iteration exists' do
            let(:current_iteration) { create(:iteration, :current, group: group, start_date: Date.yesterday, due_date: 1.day.from_now) }

            it 'returns filtered issues' do
              expect(items).to contain_exactly(current_iteration_issue)
            end

            context 'filter by negated current iteration' do
              let(:params) { { group_id: group, not: { iteration_id: ::Iteration::Predefined::Current.title } } }

              it 'returns filtered issues' do
                expect(items).to contain_exactly(item1, item5, iteration_1_issue, iteration_2_issue)
              end
            end
          end
        end

        context 'filter issues by iteration' do
          let(:params) { { iteration_id: iteration_1.id } }

          it 'returns all issues with the iteration' do
            expect(items).to contain_exactly(iteration_1_issue)
          end
        end

        context 'filter issues by multiple iterations' do
          let(:params) { { iteration_id: [iteration_1.id, iteration_2.id] } }

          it 'returns all issues with the iteration' do
            expect(items).to contain_exactly(iteration_1_issue, iteration_2_issue)
          end
        end

        context 'filter issue by iteration title' do
          let(:params) { { iteration_title: iteration_1.title } }

          it 'returns all issues with the iteration title' do
            expect(items).to contain_exactly(iteration_1_issue)
          end
        end

        context 'filter issue by negated iteration title' do
          let(:params) { { not: { iteration_title: iteration_1.title } } }

          it 'returns all issues that do not match the iteration title' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, iteration_2_issue)
          end
        end

        context 'without iteration_id param' do
          let(:params) { { iteration_id: nil } }

          it 'returns unfiltered issues' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, iteration_1_issue, iteration_2_issue)
          end
        end
      end

      context 'when filtering by health status' do
        let_it_be(:issue1) { create(:issue, project: project1, health_status: :needs_attention) }
        let_it_be(:issue2) { create(:issue, project: project1, health_status: :needs_attention) }
        let_it_be(:issue3) { create(:issue, project: project2, health_status: :needs_attention) }
        let_it_be(:issue4) { create(:issue, project: project1, health_status: nil) }
        let_it_be(:issue5) { create(:issue, project: project1, health_status: :at_risk) }
        let_it_be(:issue6) { create(:issue, project: project1, health_status: :on_track) }

        context 'filter issues by health status' do
          let(:params) { { health_status: :needs_attention } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(issue1, issue2, issue3)
          end

          context 'when searching within a specific project' do
            let(:params) { { project_id: project1.id, health_status: :needs_attention } }

            it 'returns filtered issues' do
              expect(items).to contain_exactly(issue1, issue2)
            end
          end
        end

        context 'filter issues with no health status' do
          let(:params) { { health_status: ::IssuableFinder::Params::FILTER_NONE } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, issue4)
          end
        end

        context 'filter issues with any health status' do
          let(:params) { { health_status: ::IssuableFinder::Params::FILTER_ANY } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(issue1, issue2, issue3, issue5, issue6)
          end
        end

        context 'filter issues without a sepcific health status' do
          let(:params) { { not: { health_status_filter: :needs_attention } } }

          it 'returns filtered issues' do
            expect(items).to contain_exactly(item1, item2, item3, item4, item5, issue4, issue5, issue6)
          end
        end
      end
    end
  end

  describe '#with_confidentiality_access_check' do
    let_it_be(:guest) { create(:user) }

    let_it_be(:authorized_user) { create(:user) }
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:project) { create(:project, namespace: authorized_user.namespace) }
    let_it_be(:public_issue) { create(:issue, project: project) }
    let_it_be(:confidential_issue) { create(:issue, project: project, confidential: true) }
    let_it_be(:hidden_issue) { create(:issue, project: project, author: banned_user) }

    context 'when no project filter is given' do
      let(:params) { {} }

      context 'for an auditor' do
        let(:auditor_user) { create(:user, :auditor) }

        subject { described_class.new(auditor_user, params).with_confidentiality_access_check }

        it 'returns all issues' do
          expect(subject).to include(public_issue, confidential_issue, hidden_issue)
        end
      end
    end

    context 'when searching within a specific project' do
      let(:params) { { project_id: project.id } }

      context 'for an auditor' do
        let(:auditor_user) { create(:user, :auditor) }

        subject { described_class.new(auditor_user, params).with_confidentiality_access_check }

        it 'returns all issues' do
          expect(subject).to include(public_issue, confidential_issue, hidden_issue)
        end
      end
    end
  end
end
