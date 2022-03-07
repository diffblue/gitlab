# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Projects', :js, :geo do
  include ::EE::GeoHelpers

  let!(:geo_node) { create(:geo_node) }
  let!(:synced_registry) { create(:geo_project_registry, :synced, :repository_verified) }
  let!(:sync_pending_registry) { create(:geo_project_registry, :synced, :repository_dirty) }
  let!(:sync_failed_registry) { create(:geo_project_registry, :existing_repository_sync_failed) }
  let!(:never_synced_registry) { create(:geo_project_registry) }

  def find_toast
    page.find('.gl-toast')
  end

  before do
    stub_current_geo_node(geo_node)
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'visiting geo projects initial page' do
    before do
      visit(admin_geo_projects_path)
      wait_for_requests
    end

    it 'shows all projects in the registry' do
      page.within(find('#content-body', match: :first)) do
        expect(page).to have_content(synced_registry.project.full_name)
        expect(page).to have_content(sync_pending_registry.project.full_name)
        expect(page).to have_content(sync_failed_registry.project.full_name)
        expect(page).to have_content(never_synced_registry.project.full_name)
        expect(page).not_to have_content('There are no projects to show')
      end
    end

    describe 'searching for a geo project' do
      it 'filters out projects with the search term' do
        fill_in :name, with: synced_registry.project.name
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
          expect(page).not_to have_content('There are no projects to show')
        end
      end
    end

    describe 'with no registries' do
      it 'shows empty state' do
        fill_in :name, with: 'asdfasdf'
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
          expect(page).to have_content('There are no projects to show')
        end
      end
    end
  end

  describe 'clicking on a specific dropdown option in geo projects page' do
    let(:page_url) { admin_geo_projects_path }

    before do
      visit(page_url)
      wait_for_requests

      click_link_or_button('Filter by status')
      click_link_or_button('In progress')
      wait_for_requests
    end

    it 'shows filter specific projects' do
      page.within(find('#content-body', match: :first)) do
        expect(page).not_to have_content(synced_registry.project.full_name)
        expect(page).to have_content(sync_pending_registry.project.full_name)
        expect(page).not_to have_content(sync_failed_registry.project.full_name)
        expect(page).not_to have_content(never_synced_registry.project.full_name)
      end
    end

    describe 'searching for a geo project' do
      it 'finds the project with the same name' do
        fill_in :name, with: sync_pending_registry.project.name
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end

      it 'filters out project that matches with search but shouldnt be in the view' do
        fill_in :name, with: synced_registry.project.name
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end
    end
  end

  shared_examples 'shows filter specific projects and correct labels' do
    before do
      visit(admin_geo_projects_path(sync_status: sync_status))
      wait_for_requests
    end

    it 'shows filter specific projects' do
      page.within(find('#content-body', match: :first)) do
        expected_registries.each do |registry|
          expect(page).to have_content(registry.project.full_name)
        end

        unexpected_registries.each do |registry|
          expect(page).not_to have_content(registry.project.full_name)
        end
      end

      page.within(find('.project-card', match: :first)) do
        labels.each do |label|
          expect(page).to have_content(label)
        end

        expect(page).to have_css("svg[data-testid=\"#{icon}-icon\"")
      end
    end
  end

  describe 'visiting geo synced projects page' do
    let(:sync_status) { :synced }
    let(:expected_registries) { [synced_registry] }
    let(:unexpected_registries) { [sync_pending_registry, sync_failed_registry, never_synced_registry] }
    let(:labels) { ['Status', 'Last successful sync', 'Last time verified', 'Last repository check run'] }
    let(:icon) { 'check' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'visiting geo pending synced projects page' do
    let(:sync_status) { :pending }
    let(:expected_registries) { [sync_pending_registry] }
    let(:unexpected_registries) { [synced_registry, sync_failed_registry, never_synced_registry] }
    let(:labels) { ['Status', 'Next sync scheduled at', 'Last sync attempt'] }
    let(:icon) { 'clock' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'visiting geo failed sync projects page' do
    let(:sync_status) { :failed }
    let(:expected_registries) { [sync_failed_registry] }
    let(:unexpected_registries) { [synced_registry, sync_pending_registry, never_synced_registry] }
    let(:labels) { ['Status', 'Next sync scheduled at', 'Last sync attempt'] }
    let(:icon) { 'warning-solid' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'remove an orphaned Tracking Entry' do
    before do
      synced_registry.project.destroy!
      visit(admin_geo_projects_path(sync_status: :synced))
      wait_for_requests
    end

    it 'removes an existing Geo Project' do
      card_count = page.all(:css, '.project-card').length

      page.within(find('.project-card', match: :first)) do
        page.click_button('Remove')
      end
      page.within('.modal') do
        page.click_button('Remove entry')
      end
      # Wait for remove confirmation
      expect(find_toast).to have_text('removed')

      expect(page.all(:css, '.project-card').length).to be(card_count - 1)
    end
  end

  describe 'Resync all' do
    before do
      visit(admin_geo_projects_path)
      wait_for_requests
    end

    it 'opens confirm modal and then fires job to resync all projects' do
      page.click_button('Resync all')

      page.within('.modal') do
        page.click_button('Resync all')
      end

      expect(find_toast).to have_text('All projects are being scheduled for resync')
    end
  end

  describe 'Reverify all' do
    before do
      visit(admin_geo_projects_path)
      wait_for_requests
    end

    it 'opens confirm modal and then fires job to reverify all projects' do
      page.click_button('Reverify all')

      page.within('.modal') do
        page.click_button('Reverify all')
      end

      expect(find_toast).to have_text('All projects are being scheduled for reverify')
    end
  end
end
