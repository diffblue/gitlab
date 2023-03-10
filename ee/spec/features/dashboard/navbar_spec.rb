# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '"Your work" navbar', feature_category: :navigation do
  include NavbarStructureHelper

  include_context 'dashboard navbar structure'

  let_it_be(:user) { create(:user) }

  context 'when devops operations dashboard is available' do
    before do
      stub_licensed_features(operations_dashboard: true)
      sign_in(user)

      insert_after_nav_item(
        _('Activity'),
        new_nav_item: {
          nav_item: _("Environments Dashboard"),
          nav_sub_items: []
        }
      )
      insert_after_nav_item(
        _('Environments Dashboard'),
        new_nav_item: {
          nav_item: _("Operations Dashboard"),
          nav_sub_items: []
        }
      )

      visit root_path
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when security dashboard is available' do
    before do
      stub_licensed_features(security_dashboard: true)
      sign_in(user)

      insert_after_nav_item(
        _('Activity'),
        new_nav_item: {
          nav_item: _("Security"),
          nav_sub_items: [
            _('Security dashboard'),
            _('Vulnerability report'),
            _('Settings')
          ]
        }
      )

      visit root_path
    end

    it_behaves_like 'verified navigation bar'
  end
end
