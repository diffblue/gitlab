# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates a project', :js do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(paginatable_namespace_drop_down_for_project_creation: false)
    sign_in(user)
    create(:personal_key, user: user)
  end

  it 'creates a new project' do
    visit(new_project_path)

    click_link 'Create blank project'
    fill_in(:project_name, with: 'Empty')

    expect(page).to have_checked_field 'Initialize repository with a README'
    uncheck 'Initialize repository with a README'

    page.within('#content-body') do
      click_button('Create project')
    end

    project = Project.last

    expect(current_path).to eq(project_path(project))
    expect(page).to have_content('Empty')
    expect(page).to have_content('git init')
    expect(page).to have_content('git remote')
    expect(page).to have_content(project.url_to_repo)
  end

  it 'creates a new project that is not blank' do
    stub_experiments(new_project_sast_enabled: 'candidate')

    visit(new_project_path)

    click_link 'Create blank project'
    fill_in(:project_name, with: 'With initial commits')

    expect(page).to have_checked_field 'Initialize repository with a README'
    expect(page).to have_checked_field 'Enable Static Application Security Testing (SAST)'

    page.within('#content-body') do
      click_button('Create project')
    end

    project = Project.last

    expect(current_path).to eq(project_path(project))
    expect(page).to have_content('With initial commits')
    expect(page).to have_content('Configure SAST in `.gitlab-ci.yml`, creating this file if it does not already exist')
    expect(page).to have_content('README.md Initial commit')
  end

  context 'in a subgroup they do not own' do
    let(:parent) { create(:group) }
    let!(:subgroup) { create(:group, parent: parent) }

    before do
      parent.add_owner(user)
    end

    it 'creates a new project' do
      visit(new_project_path)

      click_link 'Create blank project'
      fill_in :project_name, with: 'A Subgroup Project'
      fill_in :project_path, with: 'a-subgroup-project'

      page.find('.js-select-namespace').click
      page.find("div[role='option']", text: subgroup.full_path).click

      page.within('#content-body') do
        click_button('Create project')
      end

      expect(page).to have_content("Project 'A Subgroup Project' was successfully created")

      project = Project.last

      expect(project.namespace).to eq(subgroup)
    end
  end

  context 'in a group with DEVELOPER_MAINTAINER_PROJECT_ACCESS project_creation_level' do
    let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

    before do
      group.add_developer(user)
    end

    it 'creates a new project' do
      visit(new_project_path)

      click_link 'Create blank project'
      fill_in :project_name, with: 'a-new-project'
      fill_in :project_path, with: 'a-new-project'

      page.find('.js-select-namespace').click
      page.find("div[role='option']", text: group.full_path).click

      page.within('#content-body') do
        click_button('Create project')
      end

      expect(page).to have_content("Project 'a-new-project' was successfully created")

      project = Project.find_by(name: 'a-new-project')
      expect(project.namespace).to eq(group)
    end
  end
end
