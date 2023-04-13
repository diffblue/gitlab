# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/sidebar/_admin', feature_category: :navigation do
  let(:user) { build_stubbed(:admin) }

  before do
    allow(user).to receive(:can_admin_all_resources?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'license includes push rules feature' do
    it 'shows the link' do
      stub_licensed_features(push_rules: true)

      render

      expect(rendered).to have_link 'Push Rules'
    end
  end

  context 'license does not include push rules feature' do
    it 'hides the link' do
      stub_licensed_features(push_rules: false)

      render

      expect(rendered).not_to have_link 'Push Rules'
    end
  end
end
