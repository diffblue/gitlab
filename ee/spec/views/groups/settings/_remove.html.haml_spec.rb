# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_remove.html.haml' do
  describe 'render' do
    let(:group) { create(:group) }

    it 'enables the Remove group button and does not show an alert for a group' do
      render 'groups/settings/remove', group: group

      expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
      expect(rendered).not_to match 'data-disabled="true"'
      expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
    end

    it 'disables the Remove group button and shows an alert for a group with a paid gitlab.com plan', :saas do
      create(:gitlab_subscription, :ultimate, namespace: group)

      render 'groups/settings/remove', group: group

      expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
      expect(rendered).to match 'data-disabled="true"'
      expect(rendered).to have_selector '[data-testid="group-has-linked-subscription-alert"]'
    end

    it 'disables the Remove group button and shows an alert for a group with a legacy paid gitlab.com plan', :saas do
      create(:gitlab_subscription, :gold, namespace: group)

      render 'groups/settings/remove', group: group

      expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
      expect(rendered).to match 'data-disabled="true"'
      expect(rendered).to have_selector '[data-testid="group-has-linked-subscription-alert"]'
    end

    it 'enables the Remove group button and does not show an alert for a subgroup', :saas do
      create(:gitlab_subscription, :ultimate, namespace: group)
      subgroup = create(:group, parent: group)

      render 'groups/settings/remove', group: subgroup

      expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
      expect(rendered).not_to match 'data-disabled="true"'
      expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
    end

    it 'enables the Remove group button for group with a trial plan', :saas do
      create(:gitlab_subscription, :ultimate_trial, trial: true, namespace: group)
      render 'groups/settings/remove', group: group

      expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
      expect(rendered).not_to match 'data-disabled="true"'
      expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
    end

    context 'when delayed deletes are enabled' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it 'enables the Remove group button and does not show an alert for a group without a paid gitlab.com plan' do
        render 'groups/settings/remove', group: group

        expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
        expect(rendered).not_to match 'data-disabled="true"'
        expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
      end

      it 'disables the Remove group button and shows an alert for a group with a paid gitlab.com plan', :saas do
        create(:gitlab_subscription, :ultimate, namespace: group)

        render 'groups/settings/remove', group: group

        expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
        expect(rendered).to match 'data-disabled="true"'
        expect(rendered).to have_selector '[data-testid="group-has-linked-subscription-alert"]'
      end

      it 'enables the Remove group button and does not show an alert for a subgroup', :saas do
        create(:gitlab_subscription, :ultimate, namespace: group)
        subgroup = create(:group, parent: group)

        render 'groups/settings/remove', group: subgroup

        expect(rendered).to have_selector '[data-button-testid="remove-group-button"]'
        expect(rendered).not_to match 'data-disabled="true"'
        expect(rendered).not_to have_selector '[data-testid="group-has-linked-subscription-alert"]'
      end
    end
  end
end
