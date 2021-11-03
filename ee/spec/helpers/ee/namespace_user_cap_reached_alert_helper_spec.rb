# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::NamespaceUserCapReachedAlertHelper do
  describe '#display_namespace_user_cap_reached_alert?' do
    let_it_be(:group, refind: true) do
      create(:group, :public,
             namespace_settings: create(:namespace_settings, new_user_signups_cap: 1))
    end

    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:owner) { create(:user) }
    let_it_be(:developer) { create(:user) }

    before_all do
      group.add_owner(owner)
      group.add_developer(developer)
    end

    before do
      allow(helper).to receive(:can?).with(owner, :admin_namespace, group).and_return(true)
      allow(helper).to receive(:can?).with(developer, :admin_namespace, group).and_return(false)
    end

    it 'returns true when the user cap is reached for a user who can admin the namespace' do
      sign_in(owner)

      expect(helper.display_namespace_user_cap_reached_alert?(group)).to be true
    end

    it 'returns false when the user cap is reached for a user who cannot admin the namespace' do
      sign_in(developer)

      expect(helper.display_namespace_user_cap_reached_alert?(group)).to be false
    end

    it 'caches the result' do
      sign_in(owner)

      expect(Rails.cache).to receive(:fetch).with("namespace_user_cap_reached:#{group.id}", expires_in: 2.hours)

      helper.display_namespace_user_cap_reached_alert?(group)
    end

    it 'caches the result for a subgroup' do
      sign_in(owner)

      expect(Rails.cache).to receive(:fetch).with("namespace_user_cap_reached:#{group.id}", expires_in: 2.hours)

      helper.display_namespace_user_cap_reached_alert?(subgroup)
    end

    def sign_in(user)
      allow(helper).to receive(:current_user).and_return(user)
    end
  end
end
