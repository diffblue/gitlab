# frozen_string_literal: true

RSpec.shared_examples_for 'over the free user limit alert' do
  let_it_be(:dismiss_button) do
    '[data-testid="user-over-limit-free-plan-dismiss"]'
  end

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
  end

  describe '#dashboard_notification_limit' do
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

      it 'performs dismiss cycle', :js do
        visit_page

        expect(page).not_to have_content(alert_title_content)

        group.add_developer(create(:user))

        page.refresh

        expect(page).to have_content(alert_title_content)

        page.within('[data-testid="user-over-limit-free-plan-alert"]') do
          expect(page).to have_link('Manage members')
          expect(page).to have_link('Explore paid plans')
        end

        find(dismiss_button).click
        wait_for_requests

        page.refresh

        expect(page).not_to have_content(alert_title_content)
      end
    end
  end

  describe '#dashboard_enforcement_limit' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_feature_flags(preview_free_user_cap: true)
      stub_ee_application_setting(dashboard_enforcement_limit: dashboard_enforcement_limit)
    end

    let(:alert_title_content) do
      'user limit and has been placed in a read-only state'
    end

    context 'when over limit' do
      let(:dashboard_enforcement_limit) { 0 }

      it 'shows free user limit warning', :js do
        visit_page

        expect(page).to have_content(alert_title_content)

        page.within('[data-testid="user-over-limit-free-plan-alert"]') do
          expect(page).to have_link('Manage members')
          expect(page).to have_link('Explore paid plans')
        end

        expect(page).not_to have_css(dismiss_button)
      end
    end

    context 'when at limit' do
      let(:dashboard_enforcement_limit) { 1 }

      it 'does not show free user limit warning', :js do
        visit_page

        expect(page).not_to have_content(alert_title_content)
      end
    end

    context 'when under limit' do
      let(:dashboard_enforcement_limit) { 2 }

      it 'does not show free user limit warning', :js do
        visit_page

        expect(page).not_to have_content(alert_title_content)
      end
    end
  end
end
