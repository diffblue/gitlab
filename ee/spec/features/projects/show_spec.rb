# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project show page', :js, feature_category: :projects do
  let_it_be(:user) { create(:user) }

  let(:path) { project_path(project) }

  context "when experiment 'tier_badge' is candidate" do
    let(:tier_badge_selector) { '[data-testid="tier-badge"]' }
    let(:tier_badge_element) { page.find(tier_badge_selector) }
    let(:popover_element) { page.find('.gl-popover') }

    before do
      stub_experiments(tier_badge: :candidate)
      project.add_maintainer(user)
      sign_in(user)
      visit path
    end

    context 'when project is part of a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :repository, namespace: group) }

      it 'renders the tier badge and popover when clicked' do
        expect(tier_badge_element).to be_present

        tier_badge_element.click

        expect(popover_element.text).to include('Enhance team productivity')
        expect(popover_element.text).to include('This project uses the Free GitLab tier.')
      end
    end

    context 'when project is not part of a group' do
      let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

      it 'does not render the tier badge' do
        expect(page).not_to have_selector(tier_badge_selector)
      end
    end
  end
end
