# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::BillingMenu do
  it_behaves_like 'billing menu items' do
    let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  end
end
