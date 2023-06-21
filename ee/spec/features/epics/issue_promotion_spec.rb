# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue promotion', :js, feature_category: :portfolio_management do
  include Features::AutocompleteHelpers
  include Features::NotesHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:parent_epic) { create(:epic, group: group) }
  let!(:epic_issue) { create(:epic_issue, issue: issue, epic: parent_epic) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when epics feature is disabled' do
    it 'does not promote the issue' do
      visit project_issue_path(project, issue)

      expect(page).not_to have_content 'Promoted issue to an epic.'

      expect(issue.reload).to be_open
      expect(Epic.count).to eq(1)
    end
  end

  context 'when epics and subepics features are enabled' do
    before do
      stub_licensed_features(epics: true, subepics: true)
    end

    context 'when current user does not have permissions to promote an issue' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'does not promote the issue' do
        expect(page).not_to have_content 'Promoted issue to an epic.'

        expect(issue.reload).to be_open
        expect(Epic.count).to eq(1)
      end
    end

    context 'when current user can promote an issue' do
      before do
        group.add_developer(user)
        visit project_issue_path(project, issue)
      end

      it 'displays description' do
        fill_in 'Comment', with: '/promote'

        expect(find_autocomplete_menu).to have_text 'Promote issue to an epic'
      end

      it 'promotes the issue' do
        add_note('/promote')

        epic = Epic.last

        expect(page).to have_content 'Promoted issue to an epic.'
        expect(issue.reload).to be_closed
        expect(epic.title).to eq(issue.title)
        expect(epic.description).to eq(issue.description)
        expect(epic.author).to eq(user)
        expect(epic.parent).to eq(parent_epic)
      end

      # Spec for https://gitlab.com/gitlab-org/gitlab/-/issues/215549
      context 'if there is a remove resource milestone event' do
        let!(:resource_milestone_event) { create(:resource_milestone_event, issue: issue, action: 'remove', milestone_id: nil) }

        it 'promotes the issue' do
          add_note('/promote')

          epic = Epic.last

          expect(page).to have_content 'Promoted issue to an epic.'
          expect(issue.reload).to be_closed
          expect(epic.title).to eq(issue.title)
          expect(epic.description).to eq(issue.description)
          expect(epic.author).to eq(user)
        end
      end
    end
  end
end
