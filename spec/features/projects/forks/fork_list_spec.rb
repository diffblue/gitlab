# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'listing forks of a project' do
  include ProjectForksHelper
  include ExternalAuthorizationServiceHelpers

  let(:source) { create(:project, :public, :repository) }
  let!(:fork) { fork_project(source, nil, repository: true) }
  let(:user) { create(:user) }

  before do
    source.add_maintainer(user)
    sign_in(user)
  end

  it 'shows the forked project in the list with commit as description', :sidekiq_might_not_need_inline do
    visit project_forks_path(source)

    page.within('li.project-row') do
      expect(page).to have_content(fork.full_name)
      expect(page).to have_css('a.commit-row-message')
    end
  end

  context "when a fork is set to allow only project members to access features" do
    let(:outside_user) { create(:user) }

    before do
      sign_in(outside_user)

      allow_any_instance_of(ProjectsHelper).to receive(:able_to_see_last_commit?).and_return(false)
      allow_any_instance_of(ProjectsHelper).to receive(:able_to_see_merge_requests?).and_return(false)
      allow_any_instance_of(ProjectsHelper).to receive(:able_to_see_issues?).and_return(false)
    end

    it 'will not show that information in the original forks list' do
      visit project_forks_path(source)

      page.within('li.project-row') do
        expect(page).not_to have_css('a.commit-row-message')
        expect(page).not_to have_css('a.issues')
        expect(page).not_to have_css('a.merge-requests')
      end
    end
  end

  it 'does not show the commit message when an external authorization service is used' do
    enable_external_authorization_service_check

    visit project_forks_path(source)

    page.within('li.project-row') do
      expect(page).to have_content(fork.full_name)
      expect(page).not_to have_css('a.commit-row-message')
    end
  end
end
