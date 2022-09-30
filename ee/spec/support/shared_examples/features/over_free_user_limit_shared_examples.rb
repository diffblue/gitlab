# frozen_string_literal: true

RSpec.shared_examples_for 'over the free user limit alert' do
  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
  end

  shared_examples 'performs entire show dismiss cycle' do
    it 'shows free user limit warning and honors dismissal', :js do
      visit_page

      expect(page).not_to have_content(alert_title_content)

      group.add_developer(create(:user))

      page.refresh

      expect(page).to have_content(alert_title_content)

      page.within('[data-testid="user-over-limit-free-plan-alert"]') do
        expect(page).to have_link('Manage members')
        expect(page).to have_link('Explore paid plans')
      end

      find('[data-testid="user-over-limit-free-plan-dismiss"]').click
      wait_for_requests

      page.refresh

      expect(page).not_to have_content(alert_title_content)
    end
  end

  context 'when over limit for preview' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_feature_flags(preview_free_user_cap: true)
      # setup here so we are over the preview limit, but not the enforcement
      # this will validate we only see one banner
      stub_ee_application_setting(dashboard_notification_limit: 1)
      stub_ee_application_setting(dashboard_enforcement_limit: 3)
    end

    let(:alert_title_content) do
      'From October 19, 2022, free private groups will be limited to'
    end

    it_behaves_like 'performs entire show dismiss cycle'
  end

  context 'when reached/over limit' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_feature_flags(preview_free_user_cap: true)
      stub_ee_application_setting(dashboard_enforcement_limit: 2)
    end

    let(:alert_title_content) { "Looks like you've reached your" }

    it_behaves_like 'performs entire show dismiss cycle'
  end
end
