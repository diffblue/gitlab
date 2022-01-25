# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Path Locks', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:tree_path) { project_tree_path(project, project.repository.root_ref) }

  before do
    stub_feature_flags(bootstrap_confirmation_modals: false)

    project.add_maintainer(user)
    sign_in(user)

    visit tree_path

    wait_for_requests
  end

  it 'locking folders' do
    within '.tree-content-holder' do
      click_link "encoding"
    end

    find('.js-path-lock').click
    wait_for_requests

    page.within '.modal' do
      expect(page).to have_selector('.modal-body', visible: true)
      expect(page).to have_css('.modal-body', text: 'Are you sure you want to lock this directory?')

      click_button "OK"
    end

    expect(page).to have_link('Unlock')
  end

  it 'locking files' do
    page_tree = find('.tree-content-holder')

    within page_tree do
      click_link "VERSION"
    end

    within '.file-actions' do
      click_button "Lock"
    end

    page.within '.modal' do
      expect(page).to have_css('.modal-body', text: 'Are you sure you want to lock VERSION?')

      click_button "Okay"
    end

    expect(page).to have_button('Unlock')
  end

  it 'unlocking files' do
    within find('.tree-content-holder') do
      click_link "VERSION"
    end

    within '.file-actions' do
      click_button "Lock"
    end

    page.within '.modal' do
      click_button "Okay"
    end

    within '.file-actions' do
      click_button "Unlock"
    end

    page.within '.modal' do
      expect(page).to have_css('.modal-body', text: 'Are you sure you want to unlock VERSION?')

      click_button "Okay"
    end

    expect(page).to have_button('Lock')
  end

  it 'managing of lock list' do
    create :path_lock, path: 'encoding', user: user, project: project

    click_link "Locked Files"

    within '.locks' do
      expect(page).to have_content('encoding')

      accept_confirm(text: 'Are you sure you want to unlock encoding?') { click_link "Unlock" }

      expect(page).not_to have_content('encoding')
    end
  end
end
