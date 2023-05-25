# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group domain verification settings', :saas, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }

  before do
    stub_licensed_features(domain_verification: true)
    stub_config(pages: {
      enabled: true,
      external_http: true,
      external_https: true,
      access_control: false,
      host: "new.domain.com"
    })
    sign_in(user)
    group.add_owner(user)
  end

  subject(:visit_domain_verification_page) { visit group_settings_domain_verification_index_path(group) }

  it 'displays the side bar menu item' do
    visit_domain_verification_page

    page.within('.shortcuts-settings') do
      expect(page).to have_link _('Domain Verification'), href: group_settings_domain_verification_index_path(group)
    end
  end

  it 'displays add domain button' do
    visit_domain_verification_page

    expect(page).to have_link s_("DomainVerification|Add Domain"),
      href: new_group_settings_domain_verification_path(group)
  end

  context 'when there are no domains' do
    it 'displays no domains present message' do
      visit_domain_verification_page

      expect(page).to have_content s_('DomainVerification|No domains configured. Create a domain in a project in this group hierarchy.') # rubocop:disable Layout/LineLength
    end
  end

  context 'when there are domains' do
    let!(:project) { create(:project, group: group) }
    let!(:verified_domain) { create(:pages_domain, project: project) }
    let!(:unverified_domain) { create(:pages_domain, :unverified, project: project) }

    it 'displays all domains within group hierarchy' do
      visit_domain_verification_page

      page.within("tr#domain#{verified_domain.id}") do
        expect(page).to have_content(verified_domain.domain)
        expect(page).to have_content('Verified')
        expect(page).to have_link(href: group_settings_domain_verification_path(group, verified_domain.domain))
      end

      page.within("tr#domain#{unverified_domain.id}") do
        expect(page).to have_content(unverified_domain.domain)
        expect(page).to have_content('Unverified')
        expect(page).to have_link(href: group_settings_domain_verification_path(group, unverified_domain.domain))
      end
    end
  end
end
