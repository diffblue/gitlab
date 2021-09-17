# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Uploads', :js, :geo do
  let!(:geo_node) { create(:geo_node) }
  let!(:synced_registry) { create(:geo_upload_legacy_registry, :with_file, :attachment, success: true) }

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    stub_feature_flags(geo_upload_replication: false)

    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'visiting geo uploads initial page' do
    before do
      visit(admin_geo_uploads_path)
      wait_for_requests
    end

    it 'shows all uploads in the registry' do
      page.within(find('#content-body', match: :first)) do
        expect(page).to have_content(synced_registry.file)
        expect(page).not_to have_content('There are no uploads to show')
      end
    end

    describe 'searching for a geo upload' do
      it 'filters out uploads with the search term' do
        fill_in :name, with: synced_registry.file
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content(synced_registry.file)
          expect(page).not_to have_content('There are no uploads to show')
        end
      end
    end

    describe 'with no registries' do
      it 'shows empty state' do
        fill_in :name, with: 'asdfasdf'
        find('#project-filter-form-field').native.send_keys(:enter)

        wait_for_requests

        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_content(synced_registry.file)
          expect(page).to have_content('There are no uploads to show')
        end
      end
    end
  end

  describe 'remove an orphaned Tracking Entry' do
    before do
      synced_registry.upload.destroy!
      visit(admin_geo_uploads_path)
      wait_for_requests
    end

    it 'removes an existing Geo Upload' do
      card_count = page.all(:css, '.upload-card').length

      page.within(find('.upload-card', match: :first)) do
        page.click_button('Remove')
      end
      page.within('.modal') do
        page.click_button('Remove entry')
      end
      # Wait for remove confirmation
      expect(page.find('.gl-toast')).to have_text('removed')

      expect(page.all(:css, '.upload-card').length).to be(card_count - 1)
    end
  end
end
