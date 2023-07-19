# frozen_string_literal: true

RSpec.shared_examples_for 'over the free user limit alert' do
  let_it_be(:new_user) { create(:user) }
  let_it_be(:dismiss_button) do
    '[data-testid="user-over-limit-free-plan-dismiss"]'
  end

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
  end

  shared_context 'with over storage limit setup' do
    include NamespaceStorageHelpers

    before do
      limit = 100
      group.add_developer(new_user)
      set_dashboard_limit(group.reload, megabytes: limit)
      create(:namespace_root_storage_statistics, namespace: group, storage_size: (limit + 1).megabytes)
    end
  end

  describe 'with enforcement concerns' do
    before do
      stub_feature_flags(free_user_cap: true)
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

      context 'when over storage limits' do
        include_context 'with over storage limit setup'

        context 'with storage size check' do
          it 'does not show alerts' do
            stub_feature_flags(free_user_cap_without_storage_check: false)

            visit_page

            expect(page).to have_content(group.name)
            expect(page).not_to have_content(alert_title_content)
          end
        end

        context 'without storage size check' do
          it 'does not show alerts' do
            stub_feature_flags(free_user_cap_without_storage_check: true)

            visit_page

            expect(page).to have_content(alert_title_content)
          end
        end
      end
    end

    context 'when at limit' do
      let(:dashboard_enforcement_limit) { 1 }

      it 'does not show free user limit warning', :js do
        visit_page

        expect(page).to have_content(group.name)
        expect(page).not_to have_content(alert_title_content)
      end
    end

    context 'when under limit' do
      let(:dashboard_enforcement_limit) { 2 }

      it 'does not show free user limit warning', :js do
        visit_page

        expect(page).to have_content(group.name)
        expect(page).not_to have_content(alert_title_content)
      end
    end
  end
end
