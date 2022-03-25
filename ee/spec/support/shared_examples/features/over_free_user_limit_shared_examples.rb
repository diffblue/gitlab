# frozen_string_literal: true

RSpec.shared_examples_for 'over the free user limit alert' do
  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_feature_flags(free_user_cap: false)
    stub_feature_flags(preview_free_user_cap: true)
    stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 1)
  end

  it 'shows free user limit warning and honors dismissal', :js do
    alert_title_content = 'From June 22, 2022 (GitLab 15.1), free personal namespaces and top-level groups will be limited to'

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

    visit visit_page

    expect(page).not_to have_content(alert_title_content)
  end
end
