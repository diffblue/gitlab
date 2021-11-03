# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_transfer.html.haml' do
  describe 'render' do
    let(:group) { create(:group) }

    it 'enables the Select parent group dropdown and does not show an alert for a group' do
      render 'groups/settings/transfer', group: group

      expect(rendered).to have_button 'Select parent group'
      expect(rendered).not_to have_button 'Select parent group', disabled: true
      expect(rendered).not_to have_text "This group can't be transfered because it is linked to a subscription."
    end

    it 'disables the Select parent group dropdown and shows an alert for a group with a paid gitlab.com plan', :saas do
      create(:gitlab_subscription, :ultimate, namespace: group)

      render 'groups/settings/transfer', group: group

      expect(rendered).to have_button 'Select parent group', disabled: true
      expect(rendered).to have_text "This group can't be transfered because it is linked to a subscription."
    end

    it 'enables the Select parent group dropdown and does not show an alert for a subgroup', :saas do
      create(:gitlab_subscription, :ultimate, namespace: group)
      subgroup = create(:group, parent: group)

      render 'groups/settings/transfer', group: subgroup

      expect(rendered).to have_button 'Select parent group'
      expect(rendered).not_to have_button 'Select parent group', disabled: true
      expect(rendered).not_to have_text "This group can't be transfered because it is linked to a subscription."
    end
  end
end
