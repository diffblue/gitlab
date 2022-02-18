# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Combined registration flow', :js do
  let_it_be(:user) { create(:user) }

  let(:experiments) { {} }

  before do
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338737
    stub_const('Gitlab::QueryLimiting::Transaction::THRESHOLD', 250)
    stub_experiments(experiments)
    allow(Gitlab).to receive(:com?).and_return(true)
    sign_in(user)
    visit users_sign_up_welcome_path

    expect(page).to have_content('Welcome to GitLab')

    choose 'My company or team'
    click_on 'Continue'
  end

  context 'when combined_registration experiment variant is candidate' do
    let(:experiments) { { combined_registration: :candidate } }

    it 'A user can create a group and project' do
      page.within '.js-group-path-display' do
        expect(page).to have_content('{group}')
      end

      page.within '.js-project-path-display' do
        expect(page).to have_content('{project}')
      end

      fill_in 'group_name', with: 'test group'

      fill_in 'blank_project_name', with: 'test project'

      page.within '.js-group-path-display' do
        expect(page).to have_content('test-group')
      end

      page.within '.js-project-path-display' do
        expect(page).to have_content('test-project')
      end

      click_on 'Create project'

      expect(page).to have_content('Start your Free Ultimate Trial')
    end

    it 'a user can create a group and import a project' do
      click_on 'Import'

      page.within '.js-import-group-path-display' do
        expect(page).to have_content('{group}')
      end

      click_on 'GitHub'

      page.within('.gl-field-error') do
        expect(page).to have_content('This field is required.')
      end

      fill_in 'import_group_name', with: 'test group'

      page.within '.js-import-group-path-display' do
        expect(page).to have_content('test-group')
      end

      click_on 'GitHub'

      expect(page).to have_content('To connect GitHub repositories, you first need to authorize GitLab to access the list of your GitHub repositories.')
    end

    describe 'exiting onboarding' do
      it 'does not show a link to exit the page' do
        expect(page).not_to have_link('Exit.')
      end

      context 'when require_verification_for_namespace_creation experiment is enabled' do
        let(:experiments) { { combined_registration: :candidate, require_verification_for_namespace_creation: :candidate } }

        it 'shows a link to exit the page' do
          expect(page).to have_link('Exit.', href: exit_users_sign_up_groups_projects_path)
          expect(page).to have_content('You can always verify your account at a later time to create a group.')
        end
      end
    end
  end
end
