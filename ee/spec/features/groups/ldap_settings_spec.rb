# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit group settings', :js, feature_category: :system_access do
  let(:user) { create(:user) }
  let(:group) { create(:group, path: 'foo') }

  before do
    stub_licensed_features(ldap_group_sync_filter: true)
    stub_feature_flags(ldap_settings_unlock_groups_by_owners: true)
    allow(Gitlab.config.ldap).to receive(:enabled).and_return(true)

    group.add_owner(user)

    sign_in(user)
  end

  context 'when Admin allow owners to unlock LDAP membership' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:allow_group_owners_to_manage_ldap).and_return(true)

      visit group_ldap_group_links_path(group)
    end

    it 'the user is allow to change the membership lock',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/389951' do
      check('Allow owners to manually add users outside of LDAP')

      click_on('Save')

      expect(page).to have_selector('[data-testid="alert-info"]', text: 'LDAP settings updated')
    end
  end

  context 'when Admin disallow owners to unlock LDAP membership' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:allow_group_owners_to_manage_ldap).and_return(false)

      visit group_ldap_group_links_path(group)
    end

    it "doesn't show the option to unlock the membership" do
      expect(page).not_to have_content('Allow owners to manually add users outside of LDAP')
    end
  end
end
