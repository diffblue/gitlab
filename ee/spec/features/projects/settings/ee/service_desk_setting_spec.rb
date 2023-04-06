# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Setting', :js, :clean_gitlab_redis_cache, feature_category: :service_desk do
  let_it_be(:issuable_project_template_files) do
    {
      '.gitlab/issue_templates/project-issue-bar.md' => 'Project Issue Template Bar',
      '.gitlab/issue_templates/project-issue-foo.md' => 'Project Issue Template Foo'
    }
  end

  let_it_be(:issuable_group_template_files) do
    {
      '.gitlab/issue_templates/group-issue-bar.md' => 'Group Issue Template Bar',
      '.gitlab/issue_templates/group-issue-foo.md' => 'Group Issue Template Foo'
    }
  end

  let_it_be(:issue_template_file) do
    {
      '.gitlab/issue_templates/template.md' => 'Template file contents'
    }
  end

  let_it_be(:project_with_issue_template) { create(:project, :custom_repo, files: issue_template_file) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :custom_repo, group: group, files: issuable_project_template_files) }
  let_it_be(:group_template_repo) { create(:project, :custom_repo, files: issuable_group_template_files) }
  let_it_be(:user) { create(:user) }
  let_it_be(:presenter) { project.present(current_user: user) }

  before do
    stub_licensed_features(custom_file_templates_for_namespace: true, custom_file_templates: true)
    stub_ee_application_setting(file_template_project: project_with_issue_template)

    project.add_maintainer(user)
    sign_in(user)

    allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
    allow(::Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?).and_return(true)

    allow(::Gitlab::Email::ServiceDeskEmail).to receive(:enabled?).and_return(true)
    allow(::Gitlab::Email::ServiceDeskEmail).to receive(:address_for_key).and_return('address-suffix@example.com')

    allow_next_instance_of(Project) do |proj_instance|
      expect(proj_instance).to receive(:present).with(current_user: user).and_return(presenter)
    end

    create(:project_group_link, project: group_template_repo, group: group)
    group.update_columns(file_template_project_id: group_template_repo.id)
    visit edit_project_path(project)
  end

  it 'loads group, project and instance issue description templates', :aggregate_failures do
    within('#service-desk-template-select') do
      expect(page).to have_content(:all, 'project-issue-bar')
      expect(page).to have_content(:all, 'project-issue-foo')
      expect(page).to have_content(:all, 'group-issue-bar')
      expect(page).to have_content(:all, 'group-issue-foo')
      expect(page).to have_content(:all, 'template')
    end
  end

  it 'persists file_template_project_id on save' do
    find('#service-desk-template-select').click
    find('.gl-dropdown-item-text-primary', exact_text: 'template').click
    find('[data-testid="save_service_desk_settings_button"]').click

    wait_for_requests

    expect(project.service_desk_setting.file_template_project_id).to eq(project_with_issue_template.id)
  end
end
