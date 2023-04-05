# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::NamespaceUserCapReachedAlertHelper, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  describe '#display_namespace_user_cap_reached_alert?' do
    subject(:display_alert?) { helper.display_namespace_user_cap_reached_alert?(group) }

    context 'with a non persisted namespace' do
      let(:group) { build(:group) }

      it { is_expected.to eq(false) }
    end

    context 'with a persisted namespace' do
      let_it_be(:group, refind: true) do
        create(:group, :public, namespace_settings: create(:namespace_settings, new_user_signups_cap: 1))
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
        allow(group).to receive(:user_cap_available?).and_return(true)

        stub_cache(group)
      end

      it 'returns true when the user cap is reached for a user who can admin the namespace' do
        sign_in(owner)

        expect(display_alert?).to be true
      end

      it 'returns false when the user cap is reached for a user who cannot admin the namespace' do
        sign_in(developer)

        expect(display_alert?).to be false
      end

      it 'does not trigger reactive caching if there is no user cap set' do
        group.namespace_settings.update!(new_user_signups_cap: nil)

        sign_in(owner)

        expect(group).not_to receive(:with_reactive_cache)
        expect(display_alert?).to be false
      end

      it 'returns false when the user cap feature is unavailable' do
        allow(group).to receive(:user_cap_available?).and_return(false)

        sign_in(owner)

        expect(display_alert?).to be false
      end

      def sign_in(user)
        allow(helper).to receive(:current_user).and_return(user)
      end

      def stub_cache(group)
        group_with_fresh_memoization = Group.find(group.id)
        result = group_with_fresh_memoization.calculate_reactive_cache
        stub_reactive_cache(group, result)
      end
    end
  end
end
