# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees new onboarding flow', :js do
  before do
    stub_const('Gitlab::QueryLimiting::Transaction::THRESHOLD', 200)
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  it 'shows continuous onboarding flow pages' do
    visit '/'
    gitlab_sign_in(:user)
    visit users_sign_up_welcome_path

    expect(page).to have_content('Welcome to GitLab')

    choose 'Just me'
    click_on 'Continue'

    expect(page).to have_content('Create your group')

    fill_in 'group_name', with: 'test'

    expect(page).to have_field('group_path', with: 'test')

    click_on 'Create group'

    expect(page).to have_content('Create/import your first project')

    fill_in 'project_name', with: 'test'

    expect(page).to have_field('project_path', with: 'test')

    click_on 'Create project'

    expect(page).to have_content('Get started with GitLab')

    Sidekiq::Worker.drain_all
    click_on "Ok, let's go"

    expect(page).to have_content('Learn GitLab')
    expect(page).to have_content('GitLab is better with colleagues!')
  end
end
