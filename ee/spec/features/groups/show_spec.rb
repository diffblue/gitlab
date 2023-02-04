# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group show page', :js, feature_category: :subgroups do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:path) { group_path(group) }

  context "when experiment 'tier_badge' is candidate" do
    let(:tier_badge_element) { page.find('[data-testid="tier-badge"]') }
    let(:popover_element) { page.find('.gl-popover') }

    before do
      stub_experiments(tier_badge: :candidate)
      sign_in(user)
      visit path
    end

    it 'renders the tier badge and popover when clicked' do
      expect(tier_badge_element).to be_present

      tier_badge_element.click

      expect(popover_element.text).to include('Enhance team productivity')
      expect(popover_element.text).to include('This group and all its related projects use the Free GitLab tier.')
    end
  end
end
