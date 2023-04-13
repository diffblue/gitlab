# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::PushRulesMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/push_rule',
    title: s_('Admin|Push Rules'),
    icon: 'push-rules'

  it_behaves_like 'Admin menu without sub menus', active_routes: { controller: :push_rules }
end
