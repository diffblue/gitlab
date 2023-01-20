# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::TrialWidgetMenu, :saas, feature_category: :experimentation_conversion do
  it_behaves_like 'trial widget menu items' do
    let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  end
end
