# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Audit Events', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user) { create(:user) }
  let(:alex) { create(:user, name: 'Alex') }
  let(:group) { create(:group) }

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

    it 'does not have Audit Events button in head nav bar' do
      visit group_security_dashboard_path(group)

      expect(page).not_to have_link('Audit Events')
    end
  end

  it 'has Audit Events button in head nav bar' do
    visit group_audit_events_path(group)

    expect(page).to have_link('Audit Events')
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
        find(:link, text: 'Security & Compliance').click
        click_link 'Audit Events'
      end

      page.within('.audit-log-table') do
        expect(page).to have_content 'Changed access level from Developer to Maintainer'
        expect(page).to have_content(user.name)
        expect(page).to have_content('Alex')
      end
    end
  end

  describe 'filter by date' do
    let!(:audit_event_1) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: 5.days.ago) }
    let!(:audit_event_2) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: 3.days.ago) }
    let!(:audit_event_3) { create(:group_audit_event, entity_type: 'Group', entity_id: group.id, created_at: Date.current) }
    let!(:events_path) { :group_audit_events_path }
    let!(:entity) { group }

    it_behaves_like 'audit events date filter'
  end
end
