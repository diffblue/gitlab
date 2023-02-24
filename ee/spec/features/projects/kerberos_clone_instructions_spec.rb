# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Kerberos clone instructions', :js, feature_category: :system_access do
  include MobileHelpers

  let(:project) { create(:project, :empty_repo) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)

    allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
  end

  it 'shows Kerberos clone url' do
    visit_project

    find('.clone-dropdown-btn').click

    expect(page).to have_content(project.kerberos_url_to_repo)

    within('.git-clone-holder') do
      expect(page).to have_content('Clone with KRB5')
    end
  end

  context 'mobile component' do
    it 'shows the Kerberos clone information' do
      resize_screen_xs
      visit_project

      within('.js-mobile-git-clone') do
        find('.dropdown-toggle').click
      end

      expect(page).to have_content('Copy KRB5 clone URL')
    end
  end

  def visit_project
    visit project_path(project)
  end
end
