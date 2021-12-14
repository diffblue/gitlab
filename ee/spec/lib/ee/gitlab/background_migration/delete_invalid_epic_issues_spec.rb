# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteInvalidEpicIssues do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  let!(:users) { table(:users) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:epics) { table(:epics) }
  let!(:issues) { table(:issues) }
  let!(:epic_issues) { table(:epic_issues) }

  let!(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let!(:group) { namespaces.create!(name: 'test 1', path: 'test1') }
  let!(:sub_group) { namespaces.create!(name: 'test 2', path: 'test2', parent_id: group.id) }
  let!(:other_group) { namespaces.create!(name: 'test 3', path: 'test3') }

  let!(:project) { projects.create!(namespace_id: group.id, name: 'test 1', path: 'test1') }
  let!(:project_sub) { projects.create!(namespace_id: sub_group.id, name: 'test 1', path: 'test1') }
  let!(:project_other) { projects.create!(namespace_id: other_group.id, name: 'test 1', path: 'test1') }

  describe '#perform' do
    let!(:epic_before) { epics.create!(iid: 1, title: 'test 1', title_html: 'test 1', group_id: group.id, author_id: user.id) }
    let!(:epic) { epics.create!(iid: 2, title: 'test 2', title_html: 'test 2', group_id: group.id, author_id: user.id) }
    let!(:epic_sub) { epics.create!(iid: 3, title: 'test 3', title_html: 'test 3', group_id: sub_group.id, author_id: user.id) }
    let!(:epic_other) { epics.create!(iid: 4, title: 'test 4', title_html: 'test 4', group_id: other_group.id, author_id: user.id) }
    let!(:epic_last) { epics.create!(iid: 5, title: 'test 5', title_html: 'test 5', group_id: group.id, author_id: user.id) }

    let!(:issue) { issues.create!(iid: 1, project_id: project.id, title: 'issue 1', title_html: 'issue 1', author_id: user.id) }
    let!(:issue2) { issues.create!(iid: 2, project_id: project.id, title: 'issue 2', title_html: 'issue 2', author_id: user.id) }
    let!(:issue3) { issues.create!(iid: 6, project_id: project.id, title: 'issue 3', title_html: 'issue 3', author_id: user.id) }
    let!(:issue4) { issues.create!(iid: 7, project_id: project.id, title: 'issue 4', title_html: 'issue 4', author_id: user.id) }
    let!(:issue5) { issues.create!(iid: 8, project_id: project.id, title: 'issue 5', title_html: 'issue 5', author_id: user.id) }

    let!(:issue_sub) { issues.create!(iid: 3, project_id: project_sub.id, title: 'issue 4', title_html: 'issue 4', author_id: user.id) }
    let!(:issue_other) { issues.create!(iid: 4, project_id: project_other.id, title: 'issue 5', title_html: 'issue 5', author_id: user.id) }
    let!(:issue_other_2) { issues.create!(iid: 5, project_id: project_other.id, title: 'issue 6', title_html: 'issue 6', author_id: user.id) }
    let!(:issue_other_3) { issues.create!(iid: 6, project_id: project_other.id, title: 'issue 7', title_html: 'issue 7', author_id: user.id) }

    let!(:valid_and_invalid_epic_issues) do
      invalid_epic_issues = []
      valid_epic_issues   = []

      valid_epic_issues << epic_issues.create!(issue_id: issue_other_3.id, epic_id: epic_before.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue.id, epic_id: epic_sub.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue_sub.id, epic_id: epic_sub.id)
      invalid_epic_issues << epic_issues.create!(issue_id: issue_other.id, epic_id: epic_sub.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue_other_2.id, epic_id: epic_other.id)
      invalid_epic_issues << epic_issues.create!(issue_id: issue2.id, epic_id: epic_other.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue3.id, epic_id: epic.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue5.id, epic_id: epic_last.id)

      { valid: valid_epic_issues, invalid: invalid_epic_issues }
    end

    let(:valid_epic_issues) { valid_and_invalid_epic_issues[:valid] }
    let(:invalid_epic_issues) { valid_and_invalid_epic_issues[:invalid] }

    it 'removes invalid epic issues' do
      expect { described_class.new.perform(epic.id, epic_last.id) }.to change { epic_issues.count }.from(8).to(6)

      expect(epic_issues.all).to match_array(valid_epic_issues)
    end

    it 'searches the group hierarchy only once per epics in the same group' do
      service = described_class.new

      expect(service).to receive(:group_and_hierarchy).exactly(3).times.and_call_original

      service.perform(epic.id, epic_last.id)
    end

    it 'prevents N+1 queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        described_class.new.perform(epic.id, epic_other.id)
      end

      # recreate deleted records
      epic_issues.create!(issue_id: issue_other.id, epic_id: epic_sub.id)
      epic_issues.create!(issue_id: issue2.id, epic_id: epic_other.id)

      # create new records to delete
      issue_9 = issues.create!(iid: 9, project_id: project.id, title: 'issue 7', title_html: 'issue 7', author_id: user.id)
      issue_10 = issues.create!(iid: 10, project_id: project.id, title: 'issue 8', title_html: 'issue 8', author_id: user.id)
      epic_issues.create!(issue_id: issue_9.id, epic_id: epic_other.id)
      epic_issues.create!(issue_id: issue_10.id, epic_id: epic_other.id)

      expect { described_class.new.perform(epic.id, epic_other.id) }.not_to exceed_all_query_limit(control)
    end
  end
end
