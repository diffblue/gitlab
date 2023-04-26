# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project settings > [EE] repository', feature_category: :source_code_management do
  include Features::MirroringHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'unlicensed' do
    it 'does not show pull mirror settings', :js do
      stub_licensed_features(repository_mirrors: false)

      visit project_settings_repository_path(project)

      page.within('.project-mirror-settings') do
        expect(page).to have_selector('#url')
        expect(page).to have_selector('#mirror_direction')
        expect(page).to have_no_selector('#project_mirror', visible: false)
        expect(page).to have_no_selector('#project_mirror_user_name')
        expect(page).to have_no_selector('#project_mirror_overwrites_diverged_branches')
        expect(page).to have_no_selector('#project_mirror_trigger_builds')
      end
    end
  end

  context 'licensed' do
    before do
      stub_licensed_features(repository_mirrors: true)
    end

    it 'shows pull mirror settings', :js do
      visit project_settings_repository_path(project)

      page.within('.project-mirror-settings') do
        expect(page).to have_selector('#url')
        expect(page).to have_selector('#mirror_direction')
        expect(page).to have_selector('#project_mirror', visible: false)
        expect(page).to have_selector('#project_mirror_user_name')
        expect(page).to have_selector('#project_mirror_overwrites_diverged_branches')
        expect(page).to have_selector('#project_mirror_trigger_builds')
      end
    end

    context 'mirrored external repo', :js do
      let(:personal_access_token) { '461171575b95eeb61fba5face8ab838853d0121f' }
      let(:password) { 'my-secret-pass' }
      let(:external_project) do
        create(:project_empty_repo,
               :mirror,
               import_url: "https://#{personal_access_token}:#{password}@github.com/testngalog2/newrepository.git")
      end

      before do
        external_project.add_maintainer(user)
        visit project_settings_repository_path(external_project)
      end

      it 'does not show personal access token' do
        mirror_url = find('.mirror-url').text

        expect(mirror_url).not_to include(personal_access_token)
        expect(mirror_url).to include('https://*****:*****@github.com/')
      end

      it 'does not show password and personal access token on the page' do
        page_content = page.body

        expect(page_content).not_to include(password)
        expect(page_content).not_to include(personal_access_token)
      end
    end

    context 'with an existing pull mirror', :js do
      let(:mirrored_project) { create(:project, :repository, :mirror, namespace: user.namespace) }

      it 'deletes the mirror' do
        visit project_settings_repository_path(mirrored_project)

        find('.js-delete-mirror').click
        wait_for_requests
        mirrored_project.reload

        expect(mirrored_project.import_data).to be_nil
        expect(mirrored_project).not_to be_mirror
      end
    end

    context 'with a non-mirrored imported project', :js do
      let(:external_project) do
        create(:project_empty_repo,
               import_url: "https://12345@github.com/testngalog2/newrepository.git")
      end

      before do
        external_project.add_maintainer(user)
      end

      it 'does not show a pull mirror' do
        visit project_settings_repository_path(external_project)

        expect(page).to have_selector('.js-delete-mirror', count: 0)
        expect(page).to have_select('Mirror direction', options: %w[Pull Push])
      end
    end

    context 'when create a push mirror' do
      let(:ssh_url) { 'ssh://user@localhost/project.git' }

      before do
        visit project_settings_repository_path(project)
      end

      it 'that mirrors all branches', :js do
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'
        select_direction

        expect(page).to have_css('#mirror_branch_setting_all')
        find('#mirror_branch_setting_all').click
        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.remote_mirrors.first.only_protected_branches).to eq(false)
        expect(project.remote_mirrors.first.mirror_branch_regex).to be_nil
      end

      it 'that mirrors protected branches', :js do
        select_direction
        find('#mirror_branch_setting_protected').click

        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.remote_mirrors.first.only_protected_branches).to eq(true)
      end

      it 'that mirrors branches match regex', :js do
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'
        select_direction

        find('#mirror_branch_setting_regex').click
        fill_in 'mirror_branch_regex', with: 'text'

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.remote_mirrors.first.only_protected_branches).to be_falsey
        expect(project.remote_mirrors.first.mirror_branch_regex).to eq('text')
      end
    end

    context 'when create a pull mirror' do
      let(:ssh_url) { 'ssh://user@localhost/project.git' }

      before do
        visit project_settings_repository_path(project)
      end

      it 'that mirrors all branches', :js do
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'
        select_direction('pull')

        expect(page).to have_css('#mirror_branch_setting_all')
        find('#mirror_branch_setting_all').click
        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.mirror_branches_setting).to eq('all')
        expect(project.mirror_branch_regex).to be_nil
      end

      it 'that only mirrors protected branches', :js do
        select_direction('pull')
        find('#mirror_branch_setting_protected').click

        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.only_mirror_protected_branches).to eq(true)
      end

      it 'that mirrors branches match regex', :js do
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'
        select_direction('pull')

        find('#mirror_branch_setting_regex').click
        fill_in 'mirror_branch_regex', with: 'text'

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(page).to have_css('.badge[title="text"]', text: 'Specific branches')
        expect(project.mirror_branches_setting).to eq('regex')
        expect(project.mirror_branch_regex).to eq('text')
      end
    end

    def select_direction(direction = 'push')
      direction_select = find('#mirror_direction')
      direction_select.select(direction.capitalize)
    end
  end
end
