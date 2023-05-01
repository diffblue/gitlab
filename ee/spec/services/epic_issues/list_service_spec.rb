# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssues::ListService, feature_category: :portfolio_management do
  let_it_be(:user) { create :user }
  let_it_be(:group, refind: true) { create(:group, :private) }
  let_it_be(:project, refind: true) { create(:project_empty_repo, group: group) }
  let_it_be(:other_project) { create(:project_empty_repo, group: group) }
  let_it_be(:epic, refind: true) { create(:epic, group: group) }

  # Reloading issues here is needed because when storing datetime on postgres
  # nanoseconds precision is ignored when fetching records but not when inserting,
  # which makes the expectations fails for created_at field.
  let_it_be(:issue1) { create(:issue, project: project, weight: 1).reload }
  let_it_be(:issue2) { create(:issue, project: project).reload }
  let_it_be(:issue3) { create(:issue, project: other_project).reload }

  let_it_be(:epic_issue1) { create(:epic_issue, issue: issue1, epic: epic, relative_position: 2) }
  let_it_be(:epic_issue2) { create(:epic_issue, issue: issue2, epic: epic, relative_position: 1) }
  let_it_be(:epic_issue3) { create(:epic_issue, issue: issue3, epic: epic, relative_position: 3) }

  describe '#execute' do
    subject { described_class.new(epic, user).execute }

    context 'when epics feature is disabled' do
      it 'returns an empty array' do
        group.add_developer(user)

        expect(subject).to be_empty
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      before_all do
        create(:issue_link, source: create(:issue), target: issue1, link_type: IssueLink::TYPE_BLOCKS)
      end

      it 'does not have N+1 queries', :use_clean_rails_memory_store_caching, :request_store do
        # The control query is made with the worst case scenario:
        # * Two different issues from two different projects that belong to two different groups
        # Then a new group with a new project is created and we do the call again to check if there will be no
        # additional queries.
        group.add_developer(user)
        list_service = described_class.new(epic, user)

        new_group = create(:group, :private, parent: group)
        new_group.add_developer(user)
        new_project = create(:project, namespace: new_group)
        milestone = create(:milestone, project: project)
        milestone2 = create(:milestone, project: new_project)
        new_issue1 = create(:issue, project: project, milestone: milestone, assignees: [user])
        new_issue3 = create(:issue, project: new_project, milestone: milestone2)
        create(:epic_issue, issue: new_issue1, epic: epic, relative_position: 3)
        create(:epic_issue, issue: new_issue3, epic: epic, relative_position: 5)

        control_count = ActiveRecord::QueryRecorder.new { list_service.execute }.count

        new_group2 = create(:group, :private)
        new_group2.add_developer(user)
        milestone3 = create(:milestone, project: new_project)
        new_issue4 = create(:issue, project: new_project, milestone: milestone3)
        create(:epic_issue, issue: new_issue4, epic: epic, relative_position: 6)
        create(:issue_link, source: create(:issue), target: issue2, link_type: IssueLink::TYPE_BLOCKS)

        expect { list_service.execute }.not_to exceed_query_limit(control_count)
      end

      context 'owner can see all issues and destroy their associations' do
        before do
          group.add_developer(user)
        end

        it 'returns related issues JSON' do
          expected_result = [
            {
              id: issue2.id,
              iid: issue2.iid,
              type: issue2.issue_type.upcase,
              title: issue2.title,
              assignees: [],
              state: issue2.state,
              milestone: nil,
              weight: nil,
              confidential: false,
              reference: issue2.to_reference(full: true),
              path: "/#{project.full_path}/-/issues/#{issue2.iid}",
              relation_path: "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issue2.id}",
              epic_issue_id: epic_issue2.id,
              due_date: nil,
              created_at: issue2.created_at,
              closed_at: issue2.closed_at,
              blocked: false
            },
            {
              id: issue1.id,
              iid: issue1.iid,
              type: issue1.issue_type.upcase,
              title: issue1.title,
              assignees: [],
              state: issue1.state,
              milestone: nil,
              weight: 1,
              confidential: false,
              reference: issue1.to_reference(full: true),
              path: "/#{project.full_path}/-/issues/#{issue1.iid}",
              relation_path: "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issue1.id}",
              epic_issue_id: epic_issue1.id,
              due_date: nil,
              created_at: issue1.created_at,
              closed_at: issue1.closed_at,
              blocked: true
            },
            {
              id: issue3.id,
              iid: issue3.iid,
              type: issue3.issue_type.upcase,
              title: issue3.title,
              assignees: [],
              state: issue3.state,
              milestone: nil,
              weight: nil,
              confidential: false,
              reference: issue3.to_reference(full: true),
              path: "/#{other_project.full_path}/-/issues/#{issue3.iid}",
              relation_path: "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issue3.id}",
              epic_issue_id: epic_issue3.id,
              due_date: nil,
              created_at: issue3.created_at,
              closed_at: issue3.closed_at,
              blocked: false
            }
          ]

          expect(subject).to eq(expected_result)
        end
      end

      context 'user can see only some issues' do
        before do
          project.add_developer(user)
        end

        it 'returns related issues JSON' do
          expected_result = [
            {
              id: issue2.id,
              iid: issue2.iid,
              type: issue2.issue_type.upcase,
              title: issue2.title,
              assignees: [],
              state: issue2.state,
              milestone: nil,
              weight: nil,
              confidential: false,
              reference: issue2.to_reference(full: true),
              path: "/#{project.full_path}/-/issues/#{issue2.iid}",
              relation_path: nil,
              epic_issue_id: epic_issue2.id,
              due_date: nil,
              created_at: issue2.created_at,
              closed_at: issue2.closed_at,
              blocked: false
            },
            {
              id: issue1.id,
              iid: issue1.iid,
              type: issue1.issue_type.upcase,
              title: issue1.title,
              assignees: [],
              state: issue1.state,
              milestone: nil,
              weight: 1,
              confidential: false,
              reference: issue1.to_reference(full: true),
              path: "/#{project.full_path}/-/issues/#{issue1.iid}",
              relation_path: nil,
              epic_issue_id: epic_issue1.id,
              due_date: nil,
              created_at: issue1.created_at,
              closed_at: issue1.closed_at,
              blocked: true
            }
          ]

          expect(subject).to eq(expected_result)
        end
      end
    end
  end
end
