# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Geo Sites', :js, :geo, feature_category: :geo_replication do
  let!(:geo_site) { create(:geo_node) }

  def expect_fields(site_fields)
    site_fields.each do |field|
      expect(page).to have_field(field)
    end
  end

  def expect_no_fields(site_fields)
    site_fields.each do |field|
      expect(page).not_to have_field(field)
    end
  end

  def expect_breadcrumb(text)
    breadcrumbs = page.all(:css, '.breadcrumbs-list>li')
    expect(breadcrumbs.length).to eq(3)
    expect(breadcrumbs[0].text).to eq('Admin Area')
    expect(breadcrumbs[1].text).to eq('Geo Sites')
    expect(breadcrumbs[2].text).to eq(text)
  end

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'index' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'shows all public Geo Sites and Add site link' do
      expect(page).to have_link('Add site', href: new_admin_geo_node_path)
      page.within(find('.geo-site-core-details-grid-columns', match: :first)) do
        expect(page).to have_content(geo_site.url)
      end
    end

    context 'hashed storage warnings' do
      let(:enable_warning) { 'Please enable and migrate to hashed storage' }
      let(:migrate_warning) { 'Please migrate all existing projects' }

      context 'without hashed storage enabled' do
        let(:alert_close_button) { '[data-testid="enable_hashed_storage_alert"] .js-close' }

        before do
          stub_application_setting(hashed_storage_enabled: false)
        end

        it 'shows a dismissable warning to enable hashed storage' do
          visit admin_geo_nodes_path

          expect(page).to have_content enable_warning
          expect(page).to have_selector alert_close_button
        end

        it 'warning is dismissed and stays dimissed after refresh', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/390896' do
          visit admin_geo_nodes_path
          find(alert_close_button).click
          wait_for_requests

          expect(page).not_to have_content enable_warning

          visit current_path
          expect(page).not_to have_content enable_warning
        end
      end

      context 'with hashed storage enabled' do
        let(:alert_close_button) { '[data-testid="migrate_hashed_storage_alert"] .js-close' }

        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        context 'with all projects in hashed storage' do
          let!(:project) { create(:project) }

          it 'does not show any hashed storage warning' do
            visit admin_geo_nodes_path

            expect(page).not_to have_content enable_warning
            expect(page).not_to have_content migrate_warning
            expect(page).not_to have_selector alert_close_button
          end
        end

        context 'with at least one project in legacy storage' do
          let!(:project) { create(:project, :legacy_storage) }

          it 'shows a dismissable warning to migrate to hashed storage' do
            visit admin_geo_nodes_path

            expect(page).to have_content migrate_warning
            expect(page).to have_selector alert_close_button
          end

          it 'warning is dismissed and stays dimissed after refresh', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/389541' do
            visit admin_geo_nodes_path
            find(alert_close_button).click
            wait_for_requests

            expect(page).not_to have_content migrate_warning

            visit current_path
            expect(page).not_to have_content migrate_warning
          end
        end
      end
    end
  end

  describe 'site form fields' do
    primary_only_fields = %w(site-reverification-interval-field)
    secondary_only_fields = %w(site-selective-synchronization-field site-repository-capacity-field site-file-capacity-field site-object-storage-field)

    it 'when primary renders only primary fields' do
      geo_site.update!(primary: true)
      visit edit_admin_geo_node_path(geo_site)

      expect_fields(primary_only_fields)
      expect_no_fields(secondary_only_fields)
    end

    it 'when secondary renders only secondary fields' do
      geo_site.update!(primary: false)
      visit edit_admin_geo_node_path(geo_site)

      expect_no_fields(primary_only_fields)
      expect_fields(secondary_only_fields)
    end
  end

  describe 'create a new Geo Site' do
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      visit new_admin_geo_node_path
    end

    it 'creates a new Geo Site' do
      fill_in 'site-name-field', with: 'a site name'
      fill_in 'site-url-field', with: 'https://test.gitlab.com'
      click_button 'Save'

      wait_for_requests
      expect(page).to have_current_path admin_geo_nodes_path, ignore_query: true

      page.within(find('.geo-site-core-details-grid-columns', match: :first)) do
        expect(page).to have_content(geo_site.url)
      end
    end

    it 'includes Geo Sites in breadcrumbs' do
      expect_breadcrumb('Add New Site')
    end
  end

  describe 'update an existing Geo Site' do
    before do
      geo_site.update!(primary: true)

      visit edit_admin_geo_node_path(geo_site)
    end

    it 'updates an existing Geo Site' do
      fill_in 'site-url-field', with: 'http://newsite.com'
      fill_in 'site-internal-url-field', with: 'http://internal-url.com'
      click_button 'Save changes'

      wait_for_requests
      expect(page).to have_current_path admin_geo_nodes_path, ignore_query: true

      page.within(find('.geo-site-core-details-grid-columns', match: :first)) do
        expect(page).to have_content('http://newsite.com')
      end
    end

    it 'includes Geo Sites in breadcrumbs' do
      expect_breadcrumb('Edit Geo Site')
    end
  end

  describe 'remove an existing Geo Site' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'removes an existing Geo Site' do
      page.click_button('Remove')

      page.within('.gl-modal') do
        page.click_button('Remove site')
      end

      expect(page).to have_current_path admin_geo_nodes_path, ignore_query: true
      wait_for_requests
      expect(page).not_to have_css('.geo-site-core-details-grid-columns')
    end
  end

  describe 'with no Geo Sites' do
    before do
      geo_site.delete
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'hides the New Site button' do
      expect(page).not_to have_link('Add site', href: new_admin_geo_node_path)
    end

    it 'shows Discover GitLab Geo' do
      expect(page).to have_content('Discover GitLab Geo')
    end
  end

  describe 'Geo Site form routes' do
    routes = []

    before do
      routes = [{ path: new_admin_geo_node_path, slug: '/new' }, { path: edit_admin_geo_node_path(geo_site), slug: '/edit' }]
    end

    routes.each do |route|
      it "#{route.slug} renders the geo form" do
        visit route.path

        expect(page).to have_css(".geo-site-form-container")
        expect(page).not_to have_css(".js-geo-site-form")
      end
    end
  end
end
