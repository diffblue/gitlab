# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reset namespace pipeline minutes', :js, feature_category: :continuous_integration do
  include ::Ci::MinutesHelpers

  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  shared_examples 'resetting pipeline minutes' do
    context 'when namespace has minutes used' do
      before do
        set_ci_minutes_used(namespace, 100)
      end

      it 'resets pipeline minutes' do
        time = Time.zone.now

        travel_to(time) do
          click_button 'Reset pipeline minutes'
        end

        expect(page).to have_selector('.gl-toast')
        expect(page).to have_current_path(%r(#{namespace.path}), ignore_query: true)

        expect(namespace.reload.ci_minutes_usage.total_minutes_used).to eq(0)
        expect(namespace.ci_minutes_usage.reset_date.month).to eq(time.month)
        expect(namespace.ci_minutes_usage.reset_date.year).to eq(time.year)
      end
    end
  end

  shared_examples 'rendering error' do
    context 'when resetting pipeline minutes fails' do
      before do
        allow_next_instance_of(Ci::Minutes::ResetUsageService) do |instance|
          allow(instance).to receive(:execute).and_return(false)
        end
      end

      it 'renders edit page with an error' do
        click_button 'Reset pipeline minutes'

        expect(page).to have_current_path(%r(#{namespace.path}), ignore_query: true)
        expect(page).to have_selector('.gl-toast')
      end
    end
  end

  describe 'for user namespace' do
    let(:user) { create(:user) }
    let(:namespace) { user.namespace }

    before do
      visit admin_user_path(user)
      click_link 'Edit'
    end

    it 'reset pipeline minutes button is visible' do
      expect(page).to have_button('Reset pipeline minutes')
    end

    include_examples 'resetting pipeline minutes'
    include_examples 'rendering error'
  end

  describe 'when creating a new group' do
    before do
      visit admin_groups_path
      page.within '#content-body' do
        click_link 'New group'
      end
    end

    it 'does not display reset pipeline minutes callout' do
      expect(page).not_to have_link('Reset pipeline minutes')
    end
  end

  describe 'for group namespace' do
    let(:group) { create(:group) }
    let(:namespace) { group }

    before do
      visit admin_group_path(group)
      click_link 'Edit'
    end

    it 'reset pipeline minutes button is visible' do
      expect(page).to have_button('Reset pipeline minutes')
    end

    include_examples 'resetting pipeline minutes'
    include_examples 'rendering error'
  end
end
