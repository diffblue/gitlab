# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::CredentialsMenu, feature_category: :navigation do
  before do
    stub_licensed_features(credentials_inventory: true)
  end

  it_behaves_like 'Admin menu',
    link: '/admin/credentials',
    title: s_('Admin|Credentials'),
    icon: 'lock'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :credentials }
end
