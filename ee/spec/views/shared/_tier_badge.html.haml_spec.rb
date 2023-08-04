# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/_tier_badge.html.haml', :saas, feature_category: :groups_and_projects do
  let_it_be(:parent) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:subgroup) { create(:group, parent: parent) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:selector) { '.js-tier-badge-trigger' }

  before do
    stub_experiments(tier_badge: tier_badge)
  end

  context 'when control' do
    let(:tier_badge) { :control }

    it 'does not render anything' do
      render 'shared/tier_badge', source: parent, source_type: 'Group'

      expect(rendered).not_to have_selector(selector)
    end
  end

  context 'when candidate' do
    let(:tier_badge) { :candidate }

    context 'when free parent' do
      it 'renders tier_badge' do
        render 'shared/tier_badge', source: parent, source_type: 'Group'

        expect(rendered).to have_selector(selector)
      end
    end

    context 'when free subgroup' do
      it 'does not render anything' do
        render 'shared/tier_badge', source: subgroup, source_type: 'Group'

        expect(rendered).not_to have_selector(selector)
      end
    end

    context 'when free parent with exprired trial' do
      it 'does not render anything' do
        create(:gitlab_subscription, :expired_trial, namespace: parent) # rubocop:disable RSpec/FactoryBot/AvoidCreate

        render 'shared/tier_badge', source: parent, source_type: 'Group'

        expect(rendered).not_to have_selector(selector)
      end
    end
  end
end
