# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uploads metrics to incident', :js, feature_category: :incident_management do
  let_it_be(:incident) { create(:incident) }
  let_it_be(:project) { incident.project }
  let_it_be(:user) { create(:user, developer_projects: [project]) }

  context 'when feature is available' do
    before do
      stub_licensed_features(incident_metric_upload: true)
    end

    shared_examples 'creates, updates, and deletes metric images' do
      specify do
        upload_metric_image

        page.within find('[data-testid="metrics-tab"]') do
          expect(page).to have_link('Metric image title', href: 'http://example.gitlab.com/')
          expect(page).to have_selector('img', wait: 0)

          find('[data-testid="collapse-button"]').click
          expect(page).to have_link('Metric image title', href: 'http://example.gitlab.com/')
          expect(page).not_to have_selector('img', wait: 0)
        end

        update_metric_image

        page.within find('[data-testid="metrics-tab"]') do
          expect(page).to have_link('New metric image title', href: 'http://example.gitlab.com/new')
        end

        delete_metric_image

        page.within find('[data-testid="metrics-tab"]') do
          expect(page).not_to have_link('New metric image title', href: 'http://example.gitlab.com/new')
          expect(page).not_to have_selector('img', wait: 0)
        end
      end

      private

      def upload_metric_image
        attach_file('upload_file', Rails.root.join('spec/fixtures/dk.png'), visible: false)

        fill_in _('Text (optional)'), with: 'Metric image title'
        fill_in _('Link (optional)'), with: 'http://example.gitlab.com/'

        click_button _('Upload')
      end

      def update_metric_image
        click_button _('Edit image text or link')

        fill_in _('Text (optional)'), with: 'New metric image title'
        fill_in _('Link (optional)'), with: 'http://example.gitlab.com/new'

        click_button _('Update')
      end

      def delete_metric_image
        click_button _('Delete image')

        page.within find('.modal') do
          click_button('Delete')
        end
      end
    end

    it_behaves_like 'for each incident details route',
      'creates, updates, and deletes metric images',
      tab_text: s_('Incident|Metrics'),
      tab: 'metrics'
  end

  context 'when feature is unavailable' do
    it 'hides the Metrics tab' do
      stub_licensed_features(incident_metric_upload: false)

      sign_in(user)
      visit project_issue_path(project, incident)

      expect(page).not_to have_link(s_('Incident|Metrics'))
    end
  end
end
