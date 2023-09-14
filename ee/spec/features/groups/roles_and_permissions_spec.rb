# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Roles and Permissions', feature_category: :user_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    stub_licensed_features(custom_roles: true)
  end

  describe 'landing page' do
    before do
      visit group_settings_roles_and_permissions_path(group)
    end

    it 'shows a loading icon' do
      expect(page).to have_css(".gl-spinner[aria-label=#{_('Loading')}]")
    end
  end
end
