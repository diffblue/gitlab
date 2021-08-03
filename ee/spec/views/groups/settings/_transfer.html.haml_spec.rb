# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_transfer.html.haml' do
  describe 'render' do
    let(:group) { create(:group) }

    it 'enables the Select parent group dropdown and does not show an alert for a group' do
      render 'groups/settings/transfer', group: group

      expect(rendered).to have_selector '[data-qa-selector="select_group_dropdown"]' # rubocop:disable QA/SelectorUsage
      expect(rendered).not_to have_selector '[data-qa-selector="select_group_dropdown"][disabled]' # rubocop:disable QA/SelectorUsage
      expect(rendered).not_to have_selector '[data-testid="group-to-transfer-has-linked-subscription-alert"]'
    end

    it 'disables the Select parent group dropdown and shows an alert for a group with a paid gitlab.com plan' do
      create(:gitlab_subscription, :ultimate, namespace: group)

      render 'groups/settings/transfer', group: group

      expect(rendered).to have_selector '[data-qa-selector="select_group_dropdown"][disabled]' # rubocop:disable QA/SelectorUsage
      expect(rendered).to have_selector '[data-testid="group-to-transfer-has-linked-subscription-alert"]'
    end

    it 'enables the Select parent group dropdown and does not show an alert for a subgroup' do
      create(:gitlab_subscription, :ultimate, namespace: group)
      subgroup = create(:group, parent: group)

      render 'groups/settings/transfer', group: subgroup

      expect(rendered).to have_selector '[data-qa-selector="select_group_dropdown"]' # rubocop:disable QA/SelectorUsage
      expect(rendered).not_to have_selector '[data-qa-selector="select_group_dropdown"][disabled]' # rubocop:disable QA/SelectorUsage
      expect(rendered).not_to have_selector '[data-testid="group-to-transfer-has-linked-subscription-alert"]'
    end
  end
end
