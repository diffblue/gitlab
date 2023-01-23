# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Projects', :js, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let!(:geo_node) { create(:geo_node) }
  let!(:synced_registry) { create(:geo_project_registry, :synced, :repository_verified) }
  let!(:sync_pending_sync_registry) { create(:geo_project_registry, :synced, :repository_dirty) }

  let!(:sync_pending_verification_registry) do
    create(:geo_project_registry, :synced, :repository_verification_outdated)
  end

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
    context 'with registries' do
      before do
        visit(admin_geo_projects_path)
        wait_for_requests
      end

      it 'shows all projects in the registry' do
        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content(synced_registry.project.full_name)
          expect(page).to have_content(sync_pending_sync_registry.project.full_name)
          expect(page).to have_content(sync_pending_verification_registry.project.full_name)
          expect(page).to have_content(sync_failed_registry.project.full_name)
          expect(page).to have_content(never_synced_registry.project.full_name)
          expect(page).not_to have_content('There are no projects to show')
        end
      end

      describe 'searching for a geo project' do
        it 'filters out projects with the search term' do
          fill_in :name, with: synced_registry.project.name
          find('[data-testid="geo-projects-filter-field"]').native.send_keys(:enter)

          wait_for_requests

          page.within(find('#content-body', match: :first)) do
            expect(page).to have_content(synced_registry.project.full_name)
            expect(page).not_to have_content(sync_pending_sync_registry.project.full_name)
            expect(page).not_to have_content(sync_pending_verification_registry.project.full_name)
            expect(page).not_to have_content(sync_failed_registry.project.full_name)
            expect(page).not_to have_content(never_synced_registry.project.full_name)
            expect(page).not_to have_content('There are no projects to show')
          end
        end
      end
    end

    context 'with no registries' do
      shared_examples 'shows empty state' do
        before do
          visit(admin_geo_projects_path(params))
          wait_for_requests
        end

        it 'with correct title and description' do
          expect(page).to have_text(title)
          expect(page).to have_text(description)
        end

        it 'with no registries' do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_sync_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_verification_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end

        it 'with conditional help link' do
          expect(page.has_link?('Geo Troubleshooting')).to be(show_link)
        end
      end

      describe 'with no filter' do
        before do
          allow_next_instance_of(Geo::ProjectRegistryStatusFinder) do |instance|
            allow(instance).to receive_message_chain(:all_projects, :page).and_return([])
            allow(instance).to receive_message_chain(:all_projects, :limit).and_return([])
          end
        end

        let(:params) { nil }
        let(:title) { 'There are no projects to show' }
        let(:description) { 'No projects were found.' }
        let(:show_link) { true }

        it_behaves_like 'shows empty state'
      end

      describe 'with a search filter' do
        let(:params) { { name: 'fake registry' } }
        let(:title) { 'No results found' }
        let(:description) { 'Edit your search filter and try again.' }
        let(:show_link) { false }

        it_behaves_like 'shows empty state'
      end

      describe 'with a status filter' do
        before do
          allow_next_instance_of(Geo::ProjectRegistryStatusFinder) do |instance|
            allow(instance).to receive_message_chain(:synced_projects, :page).and_return([])
          end
        end

        let(:params) { { sync_status: :synced } }
        let(:title) { 'No results found' }
        let(:description) { 'Edit your search filter and try again.' }
        let(:show_link) { false }

        it_behaves_like 'shows empty state'
      end

      describe 'with a search filter and status filter' do
        let(:params) { { sync_status: :synced, name: 'fake registry' } }
        let(:title) { 'No results found' }
        let(:description) { 'Edit your search filter and try again.' }
        let(:show_link) { false }

        it_behaves_like 'shows empty state'
      end
    end
  end

  describe 'clicking on a specific dropdown option in geo projects page' do
    let(:page_url) { admin_geo_projects_path }

    before do
      visit(page_url)
      wait_for_requests

      click_link_or_button('All projects')
      find('li', text: 'In progress').click
      wait_for_requests
    end

    it 'shows filter specific projects' do
      page.within(find('#content-body', match: :first)) do
        expect(page).not_to have_content(synced_registry.project.full_name)
        expect(page).to have_content(sync_pending_sync_registry.project.full_name)
        expect(page).to have_content(sync_pending_verification_registry.project.full_name)
        expect(page).not_to have_content(sync_failed_registry.project.full_name)
        expect(page).not_to have_content(never_synced_registry.project.full_name)
      end
    end

    describe 'searching for a geo project' do
      it 'finds the project with the same name' do
        fill_in :name, with: sync_pending_sync_registry.project.name
        find('[data-testid="geo-projects-filter-field"]').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).to have_content(sync_pending_sync_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_verification_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end

      it 'filters out project that matches with search but shouldnt be in the view' do
        fill_in :name, with: synced_registry.project.name
        find('[data-testid="geo-projects-filter-field"]').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_sync_registry.project.full_name)
          expect(page).not_to have_content(sync_pending_verification_registry.project.full_name)
          expect(page).not_to have_content(sync_failed_registry.project.full_name)
          expect(page).not_to have_content(never_synced_registry.project.full_name)
        end
      end
    end
  end

  shared_examples 'shows filter specific projects and correct labels' do
    before do
      visit(admin_geo_projects_path(params))
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

        expect(page).to have_text(status_text)
        expect(page).to have_css(".#{status_color}")
        expect(page).to have_css("svg[data-testid=\"#{status_icon}-icon\"")
      end
    end
  end

  describe 'visiting geo synced projects page' do
    let(:params) { { sync_status: :synced } }
    let(:expected_registries) { [synced_registry] }

    let(:unexpected_registries) do
      [
        sync_pending_sync_registry,
        sync_pending_verification_registry,
        sync_failed_registry,
        never_synced_registry
      ]
    end

    let(:labels) { ['Status', 'Last successful sync', 'Last time verified', 'Last repository check run'] }
    let(:status_icon) { 'check-circle-filled' }
    let(:status_color) { 'gl-text-green-500' }
    let(:status_text) { 'Synced' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'visiting geo pending synced and searching pending sync on projects page' do
    let(:params) { { sync_status: :pending, name: sync_pending_sync_registry.project.name } }
    let(:expected_registries) { [sync_pending_sync_registry] }

    let(:unexpected_registries) do
      [
        synced_registry,
        sync_pending_verification_registry,
        sync_failed_registry,
        never_synced_registry
      ]
    end

    let(:labels) { ['Status', 'Next sync scheduled at', 'Last sync attempt'] }
    let(:status_icon) { 'status_pending' }
    let(:status_color) { 'gl-text-orange-500' }
    let(:status_text) { 'Pending synchronization' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'visiting geo pending synced and searching pending verification on projects page' do
    let(:params) { { sync_status: :pending, name: sync_pending_verification_registry.project.name } }
    let(:expected_registries) { [sync_pending_verification_registry] }

    let(:unexpected_registries) do
      [
        synced_registry,
        sync_pending_sync_registry,
        sync_failed_registry,
        never_synced_registry
      ]
    end

    let(:labels) { ['Status', 'Next sync scheduled at', 'Last sync attempt'] }
    let(:status_icon) { 'status_pending' }
    let(:status_color) { 'gl-text-orange-500' }
    let(:status_text) { 'Pending verification' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'visiting geo failed sync projects page' do
    let(:params) { { sync_status: :failed } }
    let(:expected_registries) { [sync_failed_registry] }

    let(:unexpected_registries) do
      [
        synced_registry,
        sync_pending_sync_registry,
        sync_pending_verification_registry,
        never_synced_registry
      ]
    end

    let(:labels) { ['Status', 'Next sync scheduled at', 'Last sync attempt'] }
    let(:status_icon) { 'status_failed' }
    let(:status_color) { 'gl-text-red-500' }
    let(:status_text) { 'Failed' }

    it_behaves_like 'shows filter specific projects and correct labels'
  end

  describe 'searching for never synced registry on projects pag' do
    let(:params) { { name: never_synced_registry.project.name } }
    let(:expected_registries) { [never_synced_registry] }

    let(:unexpected_registries) do
      [
        synced_registry,
        sync_pending_sync_registry,
        sync_pending_verification_registry,
        sync_failed_registry
      ]
    end

    let(:labels) { ['Status', 'Next sync scheduled at', 'Last sync attempt'] }
    let(:status_icon) { 'status_notfound' }
    let(:status_color) { 'gl-text-gray-500' }
    let(:status_text) { 'Never' }

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
