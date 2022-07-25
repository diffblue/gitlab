# frozen_string_literal: true

RSpec.shared_examples_for 'over the free user limit alert' do
  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
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

      page.refresh

      expect(page).not_to have_content(alert_title_content)
    end
  end

  context 'when over limit for preview' do
    before do
      stub_feature_flags(free_user_cap: false)
      stub_feature_flags(preview_free_user_cap: true)
      group.namespace_settings.update_column(:include_for_free_user_cap_preview, true)
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 1)
    end

    let(:alert_title_content) do
      'From October 19, 2022, free personal namespaces and top-level groups will be limited to'
    end

    it_behaves_like 'performs entire show dismiss cycle'
  end

  context 'when reached/over limit' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
    end

    let(:alert_title_content) { "Looks like you've reached your" }

    it_behaves_like 'performs entire show dismiss cycle'
  end
end

RSpec.shared_examples_for 'user namespace over the free user limit alert' do
  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
  end

  shared_examples 'performs entire user namespace show dismiss cycle' do
    it 'shows free user limit warning and honors dismissal', :js do
      visit_page

      expect(page).not_to have_content(alert_title_content)

      project.add_developer(create(:user))

      page.refresh

      expect(page).to have_content(alert_title_content)

      page.within('[data-testid="user-over-limit-free-plan-alert"]') do
        expect(page).to have_link('View all personal projects')
      end

      find('[data-testid="user-over-limit-free-plan-dismiss"]').click

      page.refresh

      expect(page).not_to have_content(alert_title_content)
    end
  end

  context 'when over limit for preview' do
    before do
      stub_feature_flags(free_user_cap: false)
      stub_feature_flags(preview_free_user_cap: true)
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 1)
    end

    let(:alert_title_content) do
      'From October 19, 2022, you can have a maximum'
    end

    it_behaves_like 'performs entire user namespace show dismiss cycle'
  end

  context 'when reached/over limit' do
    before do
      stub_feature_flags(free_user_cap: true)
      stub_feature_flags(preview_free_user_cap: false)
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
    end

    let(:alert_title_content) do
      "You've reached your #{::Namespaces::FreeUserCap::FREE_USER_LIMIT} member limit"
    end

    it_behaves_like 'performs entire user namespace show dismiss cycle'
  end
end
