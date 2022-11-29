# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DevOps Reports page', :js, feature_category: :devops_reports do
  tabs_selector = '.gl-tabs-nav'
  tab_item_selector = '.nav-item'
  active_tab_selector = '.nav-link.active'
  tabs = [
    {
      value: 'sec',
      text: 'Sec'
    },
    {
      value: 'ops',
      text: 'Ops'
    },
    {
      value: 'devops-score',
      text: 'DevOps Score'
    }
  ]

  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'with ultimate license' do
    before do
      stub_licensed_features(devops_adoption: true)
    end

    it 'shows the tabbed layout' do
      visit admin_dev_ops_reports_path

      expect(page).to have_selector tabs_selector
    end

    it 'shows the correct tabs' do
      visit admin_dev_ops_reports_path

      within tabs_selector do
        expect(page.all(:css, tab_item_selector).length).to be(6)
        expect(page).to have_text 'Overview Dev Sec Ops DevOps Score'
      end
    end

    it 'defaults to the Overview tab' do
      visit admin_dev_ops_reports_path

      within tabs_selector do
        expect(page).to have_selector active_tab_selector, text: 'Overview'
      end
    end

    shared_examples 'displays tab content' do |tab|
      it "displays the #{tab} tab content when selected" do
        visit admin_dev_ops_reports_path

        click_link tab

        within tabs_selector do
          expect(page).to have_selector active_tab_selector, text: tab
        end
      end
    end

    tabs.each do |tab|
      it_behaves_like 'displays tab content', tab[:text]
    end

    it 'does not add the tab param when the Overview tab is selected' do
      visit admin_dev_ops_reports_path

      within tabs_selector do
        click_link 'Overview'
      end

      expect(page).to have_current_path(admin_dev_ops_reports_path)
    end

    shared_examples 'appends the tab param to the url' do |tab, text|
      it "adds the ?tab=#{tab} param when the #{text} tab is selected" do
        visit admin_dev_ops_reports_path

        click_link text

        expect(page).to have_current_path(admin_dev_ops_reports_path(tab: tab))
      end
    end

    tabs.each do |tab|
      it_behaves_like 'appends the tab param to the url', tab[:value], tab[:text]
    end

    it 'shows the devops core tab when the tab param is set' do
      visit admin_dev_ops_reports_path(tab: 'devops-score')

      within tabs_selector do
        expect(page).to have_selector active_tab_selector, text: 'DevOps Score'
      end
    end

    context 'the devops score tab' do
      it 'has dismissable intro callout' do
        visit admin_dev_ops_reports_path(tab: 'devops-score')

        expect(page).to have_content 'Introducing Your DevOps Reports'

        page.within(find('[data-testid="devops-score-container"]')) do
          find('[data-testid="close-icon"]').click
        end

        expect(page).not_to have_content 'Introducing Your DevOps Reports'
      end

      context 'when usage ping is disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        it 'shows empty state' do
          visit admin_dev_ops_reports_path(tab: 'devops-score')

          expect(page).to have_text('Service ping is off')
        end

        it 'hides the intro callout' do
          visit admin_dev_ops_reports_path(tab: 'devops-score')

          expect(page).not_to have_content 'Introducing Your DevOps Reports'
        end
      end

      context 'when there is no data to display' do
        it 'shows empty state' do
          stub_application_setting(usage_ping_enabled: true)

          visit admin_dev_ops_reports_path(tab: 'devops-score')

          expect(page).to have_content('Data is still calculating')
        end
      end

      context 'when there is data to display' do
        it 'shows the DevOps Score app' do
          stub_application_setting(usage_ping_enabled: true)
          create(:dev_ops_report_metric)

          visit admin_dev_ops_reports_path(tab: 'devops-score')

          expect(page).to have_selector('[data-testid="devops-score-app"]')
        end
      end
    end
  end

  context 'without ultimate license' do
    before do
      stub_licensed_features(devops_adoption: false)
    end

    it 'does not show the tabbed layout' do
      visit admin_dev_ops_reports_path

      expect(page).not_to have_selector tabs_selector
    end
  end
end
