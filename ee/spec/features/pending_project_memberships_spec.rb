# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pending project memberships', :js, feature_category: :projects do
  let_it_be(:developer) { create(:user) }

  before do
    sign_in(developer)
  end

  context 'with a private project in a private group' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:project) { create(:project, :private, namespace: group) }
    let_it_be(:membership) { create(:project_member, :awaiting, :developer, source: project, user: developer) }

    it 'a pending project member gets a 404 for a private project' do
      visit project_path(project)

      expect(page).to have_content "Page Not Found"
    end

    it "a pending project member gets a 404 for the project's private group" do
      visit group_path(group)

      expect(page).to have_content "Page Not Found"
    end

    it "a project member can see the project's private group once the membership transitions to active" do
      membership.activate!

      visit group_path(group)

      expect(page).to have_content group.name
      expect(page).to have_content "Group ID: #{group.id}"
      expect(page).to have_content project.name
    end

    context 'when a pending group membership is created with an existing pending project membership' do
      it "a pending member gets a 404 for the project's private group" do
        create(:group_member, :awaiting, :developer, source: group, user: developer)

        visit group_path(group)

        expect(page).to have_content "Page Not Found"
      end
    end
  end

  context 'with a public project in a public group' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, namespace: group) }

    before_all do
      create(:project_member, :awaiting, :developer, source: project, user: developer)
    end

    it 'a pending project member sees a public project as if not a member' do
      visit project_path(project)

      expect(page).to have_content "Project information"
      expect(page).not_to have_content "Security and Compliance"
      expect(page).not_to have_content "Infrastructure"
    end

    it "a pending project member sees the project's public group as if not a member" do
      visit group_path(group)

      expect(page).to have_content "Group ID: #{group.id}"
      expect(page).not_to have_content "New project"
      expect(page).not_to have_content "Recent activity"
    end
  end

  context 'with a subgroup project' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:subgroup) { create(:group, :private, parent: group) }
    let_it_be(:project) { create(:project, :private, namespace: subgroup) }

    before_all do
      create(:project_member, :awaiting, :developer, source: project, user: developer)
    end

    it 'a pending project member sees the root group as if not a member' do
      visit group_path(group)

      expect(page).to have_content "Page Not Found"
    end
  end
end
