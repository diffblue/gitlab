# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'displays new user signups cap alert', :js, feature_category: :experimentation_expansion do
  let_it_be(:admin) { create(:admin) }

  let(:help_page_href) { help_page_path('user/admin_area/settings/sign_up_restrictions.md') }
  let(:expected_content) { 'Your instance has reached its user cap' }

  context 'when reached active users cap', :do_not_mock_admin_mode_setting do
    before do
      allow(User).to receive(:billable).and_return((0..9))
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:new_user_signups_cap).and_return(9)

      gitlab_sign_in(admin)
    end

    it 'displays and dismiss alert' do
      expect(page).to have_content(expected_content)
      expect(page).to have_link('usage caps', href: help_page_href)

      visit root_dashboard_path
      find('.js-new-user-signups-cap-reached .gl-dismiss-btn').click

      expect(page).not_to have_content(expected_content)
      expect(page).not_to have_link('usage caps', href: help_page_href)
    end
  end
end
