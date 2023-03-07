# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Path Locks', :js, feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:tree_path) { project_tree_path(project, project.repository.root_ref) }

  before do
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

    accept_gl_confirm('Are you sure you want to lock this directory?')

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

    accept_gl_confirm('Are you sure you want to lock VERSION?', button_text: 'Okay')

    expect(page).to have_button('Unlock')
  end

  it 'unlocking files' do
    within find('.tree-content-holder') do
      click_link "VERSION"
    end

    within '.file-actions' do
      click_button "Lock"
    end

    accept_gl_confirm('Are you sure you want to lock VERSION?', button_text: 'Okay')

    expect(page).to have_button('Unlock')

    within '.file-actions' do
      click_button "Unlock"
    end

    accept_gl_confirm('Are you sure you want to unlock VERSION?', button_text: 'Okay')

    expect(page).to have_link('Lock')
  end

  it 'managing of lock list' do
    create :path_lock, path: 'encoding', user: user, project: project

    click_link "Locked files"

    within '.locks' do
      expect(page).to have_content('encoding')
    end

    click_link "Unlock"

    accept_gl_confirm('Are you sure you want to unlock encoding?')

    expect(page).not_to have_content('encoding')
  end
end
