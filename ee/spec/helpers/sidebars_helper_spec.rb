# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SidebarsHelper, feature_category: :navigation do
  describe '#super_sidebar_nav_panel' do
    it 'returns Security Panel for security nav' do
      expect(helper.super_sidebar_nav_panel(nav: 'security')).to be_a(Sidebars::Security::Panel)
    end
  end
end
