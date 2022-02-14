# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pending group memberships', :js do
  let_it_be(:developer) { create(:user) }

  before do
    sign_in(developer)
  end

  context 'with a public group' do
    let_it_be(:group) { create(:group, :public) }

    it 'a pending member sees a public group as if not a member' do
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit group_path(group)

      expect(page).to have_content "Group ID: #{group.id}"
      expect(page).not_to have_content "New project"
      expect(page).not_to have_content "Recent activity"
    end

    it 'a pending member sees a public group with a project as if not a member' do
      project = create(:project, :public, namespace: group)
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit group_path(group)

      expect(page).to have_content "Group ID: #{group.id}"
      expect(page).to have_content project.name
      expect(page).not_to have_content "New project"
      expect(page).not_to have_content "Recent activity"
    end

    it 'a pending group member gets a 404 for a private project in the group' do
      project = create(:project, :private, namespace: group)
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit project_path(project)

      expect(page).to have_content "Page Not Found"
    end
  end

  context 'with a private group' do
    let_it_be(:group) { create(:group, :private) }

    it 'a pending member gets a 404 for a private group' do
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit group_path(group)

      expect(page).to have_content 'Page Not Found'
    end
  end

  context 'with a subgroup' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:subgroup) { create(:group, :private, parent: group) }

    it 'a pending member of the root group sees the root group as if not a member' do
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit group_path(group)

      expect(page).to have_content 'Page Not Found'
    end

    it 'a pending member of the root group sees a subgroup as if not a member' do
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit group_path(subgroup)

      expect(page).to have_content 'Page Not Found'
    end

    it 'a pending member of the root group sees a subgroup project as if not a member' do
      project = create(:project, :private, namespace: subgroup)
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit project_path(project)

      expect(page).to have_content 'Page Not Found'
    end

    it 'a pending member of a subgroup sees a root group as if not a member' do
      create(:group_member, :awaiting, :developer, source: subgroup, user: developer)

      visit group_path(group)

      expect(page).to have_content 'Page Not Found'
    end

    it 'a pending member of a subgroup sees a project as if not a member' do
      project = create(:project, :private, namespace: subgroup)
      create(:group_member, :awaiting, :developer, source: subgroup, user: developer)

      visit project_path(project)

      expect(page).to have_content 'Page Not Found'
    end

    it 'a member with an active group membership and a pending subgroup membership sees a subgroup project as if the pending membership does not exist' do
      project = create(:project, :private, namespace: subgroup)
      create(:group_member, :guest, source: group, user: developer)
      create(:group_member, :awaiting, :maintainer, source: subgroup, user: developer)

      visit project_path(project)

      expect(page).to have_content project.name
      expect(page).to have_content 'Project information'
      expect(page).to have_content 'Issues'
      expect(page).not_to have_content 'Settings'
    end
  end

  context 'with a shared group' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:other_group) { create(:group, :private) }

    before_all do
      create(:group_group_link, shared_group: other_group, shared_with_group: group)
    end

    it 'a pending member of the invited group sees a project in the shared group as if not a member' do
      project = create(:project, namespace: other_group)
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit project_path(project)

      expect(page).to have_content 'Page Not Found'
    end
  end

  context 'with a shared project' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:other_group) { create(:group, :private) }
    let_it_be(:project) { create(:project, :private, namespace: other_group) }

    before_all do
      create(:project_group_link, group: group, project: project)
    end

    it "a pending member of the invited group sees the shared project's group as if not a member" do
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit group_path(other_group)

      expect(page).to have_content 'Page Not Found'
    end

    it "a pending member of the invited group sees the shared project as if not a member" do
      create(:group_member, :awaiting, :developer, source: group, user: developer)

      visit project_path(project)

      expect(page).to have_content 'Page Not Found'
    end
  end
end
