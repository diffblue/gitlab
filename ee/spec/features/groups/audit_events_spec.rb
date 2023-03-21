# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Audit Events', :js, feature_category: :audit_events do
  include Features::MembersHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:alex) { create(:user, name: 'Alex') }
  let_it_be_with_reload(:group) { create(:group) }

  before do
    group.add_owner(user)
    group.add_developer(alex)
    sign_in(user)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(audit_events: false)
    end

    it 'returns 404' do
      reqs = inspect_requests do
        visit group_audit_events_path(group)
      end

      expect(reqs.first.status_code).to eq(404)
    end

    it 'does not have Audit events button in head nav bar' do
      visit group_security_dashboard_path(group)

      expect(page).not_to have_link('Audit events')
    end
  end

  it 'has Audit events button in head nav bar' do
    visit group_audit_events_path(group)

    expect(page).to have_link('Audit events')
  end

  describe 'changing a user access level' do
    it "appears in the group's audit events" do
      visit group_group_members_path(group)

      wait_for_requests

      page.within first_row do
        click_button 'Developer'
        click_button 'Maintainer'
      end

      page.within('.sidebar-top-level-items') do
        find(:link, text: 'Security and Compliance').click
        click_link 'Audit events'
      end

      page.within('.audit-log-table') do
        expect(page).to have_content 'Changed access level from Developer to Maintainer'
        expect(page).to have_content(user.name)
        expect(page).to have_content('Alex')
      end
    end
  end

  describe 'audit event filter' do
    let_it_be(:events_path) { :group_audit_events_path }
    let_it_be(:entity) { group }

    describe 'filter by date' do
      let_it_be(:audit_event_1) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: 5.days.ago) }
      let_it_be(:audit_event_2) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: 3.days.ago) }
      let_it_be(:audit_event_3) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: Date.current) }

      it_behaves_like 'audit events date filter'
    end

    context 'signed in as a developer' do
      before do
        sign_in(alex)
      end

      describe 'filter by author' do
        let_it_be(:audit_event_1) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: Date.today, ip_address: '1.1.1.1', author_id: alex.id) }
        let_it_be(:audit_event_2) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: Date.today, ip_address: '0.0.0.0', author_id: user.id) }
        let_it_be(:author) { user }

        it_behaves_like 'audit events author filtering without entity admin permission'
      end
    end
  end
end
