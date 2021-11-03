# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MoveEpicIssuesAfterEpics, schema: 20181228175414 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:epic_issues) { table(:epic_issues) }

  subject { described_class.new }

  describe '#perform' do
    let(:epic_params) do
      {
        title: 'Epic',
        title_html: 'Epic',
        group_id: group.id,
        author_id: user.id
      }
    end

    let(:issue_params) do
      {
        title: 'Issue',
        title_html: 'Issue',
        project_id: project.id,
        author_id: user.id
      }
    end

    let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
    let(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }

    context 'when there are epic_issues present' do
      let(:project) { projects.create!(namespace_id: group.id, name: 'foo') }
      let(:base_epic) { epics.create!(epic_params.merge(iid: 3, relative_position: 500)) }
      let(:issue_1) { issues.create!(issue_params.merge(iid: 1)) }
      let(:issue_2) { issues.create!(issue_params.merge(iid: 2)) }
      let(:issue_3) { issues.create!(issue_params.merge(iid: 3)) }

      let!(:epic_1) { epics.create!(epic_params.merge(iid: 1, relative_position: 100)) }
      let!(:epic_2) { epics.create!(epic_params.merge(iid: 2, relative_position: 5000)) }
      let!(:epic_issue_1) { epic_issues.create!(issue_id: issue_1.id, epic_id: base_epic.id, relative_position: 400) }
      let!(:epic_issue_2) { epic_issues.create!(issue_id: issue_2.id, epic_id: base_epic.id, relative_position: 5010) }
      let!(:epic_issue_3) { epic_issues.create!(issue_id: issue_3.id, epic_id: base_epic.id, relative_position: Gitlab::Database::MAX_INT_VALUE - 10) }

      before do
        subject.perform(epics.first.id, epics.last.id)
      end

      it 'does not change relative_position of epics' do
        expect(base_epic.relative_position).to eq(500)
        expect(epic_1.relative_position).to eq(100)
        expect(epic_2.relative_position).to eq(5000)
      end

      it 'moves epic_issues after epics' do
        expect(epic_issue_1.reload.relative_position).to be > 5000
        expect(epic_issue_2.reload.relative_position).to be > 5000
      end

      it 'keeps epic_issues order' do
        expect(epic_issue_1.reload.relative_position).to be < epic_issue_2.reload.relative_position
      end

      it 'does not change the relative_position of epic_issue getting to the max value' do
        expect(epic_issue_3.reload.relative_position).to eq(Gitlab::Database::MAX_INT_VALUE - 10)
      end
    end

    context 'when there are no epics' do
      it 'runs correctly' do
        expect(subject.perform(1, 10)).to be_nil
      end
    end

    context 'when there are no epic_issues' do
      it 'runs correctly' do
        epics.create!(epic_params.merge(iid: 3, relative_position: 500))

        expect(subject.perform(1, 10)).to be_zero
      end
    end
  end
end
