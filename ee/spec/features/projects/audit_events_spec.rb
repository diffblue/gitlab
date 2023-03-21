# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Audit Events', :js, feature_category: :audit_events do
  include Features::MembersHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:pete) { create(:user, name: 'Pete') }
  let_it_be_with_reload(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(audit_events: false)
    end

    it 'returns 404' do
      reqs = inspect_requests do
        visit project_audit_events_path(project)
      end

      expect(reqs.first.status_code).to eq(404)
    end

    it 'does not have Audit Events button in head nav bar' do
      visit edit_project_path(project)

      expect(page).not_to have_link('Audit events')
    end
  end

  context 'unlicensed but we show promotions' do
    before do
      stub_licensed_features(audit_events: false)
      allow(License).to receive(:current).and_return(nil)
      stub_application_setting(check_namespace_plan: false)
      allow(LicenseHelper).to receive(:show_promotions?).and_return(true)
    end

    include_context '"Security and Compliance" permissions' do
      let(:response) { inspect_requests { visit project_audit_events_path(project) }.first }
    end

    it 'returns 200' do
      reqs = inspect_requests do
        visit project_audit_events_path(project)
      end

      expect(reqs.first.status_code).to eq(200)
    end

    it 'has Audit Events button in head nav bar' do
      visit project_audit_events_path(project)

      expect(page).to have_link('Audit events')
    end

    it 'does not have Project audit events in the header' do
      visit project_audit_events_path(project)

      expect(page).not_to have_content('Project audit events')
    end
  end

  it 'has Audit Events button in head nav bar' do
    visit project_audit_events_path(project)

    expect(page).to have_link('Audit events')
  end

  it 'has Project audit events in the header' do
    visit project_audit_events_path(project)

    expect(page).to have_content('Project audit events')
  end

  describe 'adding an SSH key' do
    let(:ssh_key) { Gitlab::SSHPublicKey.new(SSHData::PrivateKey::RSA.generate(3072).public_key.openssh).key_text }

    it "appears in the project's audit events" do
      stub_licensed_features(audit_events: true)

      visit new_project_deploy_key_path(project)

      fill_in 'deploy_key_title', with: 'laptop'
      fill_in 'deploy_key_key', with: "#{ssh_key} user@laptop"

      click_button 'Add key'

      visit project_audit_events_path(project)

      expect(page).to have_content('Added deploy key')

      visit project_deploy_keys_path(project)

      click_button 'Remove'
      click_button 'Remove deploy key'

      visit project_audit_events_path(project)

      wait_for('Audit event background creation job is done', polling_interval: 0.5, reload: true) do
        page.has_content?('Removed deploy key', wait: 0)
      end
    end
  end

  describe 'changing a user access level' do
    before do
      project.add_developer(pete)
    end

    it "appears in the project's audit events" do
      visit project_project_members_path(project)

      page.within find_member_row(pete) do
        click_button 'Developer'
        click_button 'Maintainer'
      end

      page.within('.sidebar-top-level-items') do
        find(:link, text: 'Security and Compliance').click
        click_link 'Audit events'
      end

      page.within('.audit-log-table') do
        expect(page).to have_content 'Changed access level from Developer to Maintainer'
        expect(page).to have_content(project.first_owner.name)
        expect(page).to have_content('Pete')
      end
    end
  end

  describe 'changing merge request approval permission for authors and reviewers' do
    before do
      stub_licensed_features(merge_request_approvers: true)
      project.add_developer(pete)
    end

    it "appears in the project's audit events", :js do
      visit project_settings_merge_requests_path(project)

      page.within('[data-testid="merge-request-approval-settings"]') do
        find('[data-testid="prevent-author-approval"] > input').set(false)
        find('[data-testid="prevent-committers-approval"] > input').set(true)
        click_button 'Save changes'
      end

      wait_for_all_requests

      page.within('.sidebar-top-level-items') do
        click_link 'Security and Compliance'

        wait_for_all_requests

        click_link 'Audit events'
      end

      wait_for_all_requests

      page.within('.audit-log-table') do
        expect(page).to have_content(project.first_owner.name)
        expect(page).to have_content('Changed prevent merge request approval from authors')
        expect(page).to have_content('Changed prevent merge request approval from committers')
        expect(page).to have_content(project.name)
      end
    end
  end

  describe 'combined list of authenticated and unauthenticated users' do
    let_it_be(:audit_event_1) { create(:project_audit_event, :unauthenticated, entity_type: 'Project', entity_id: project.id) }
    let_it_be(:audit_event_2) { create(:project_audit_event, author_id: non_existing_record_id, entity_type: 'Project', entity_id: project.id) }
    let_it_be(:audit_event_3) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id) }

    it 'displays the correct authors names' do
      visit project_audit_events_path(project)

      wait_for_all_requests

      page.within('.audit-log-table') do
        expect(page).to have_content('An unauthenticated user')
        expect(page).to have_content("#{audit_event_2.author_name} (removed)")
        expect(page).to have_content(audit_event_3.user.name)
      end
    end
  end

  describe 'audit event filter' do
    let_it_be(:events_path) { :project_audit_events_path }
    let_it_be(:entity) { project }

    describe 'filter by date' do
      let_it_be(:audit_event_1) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: 5.days.ago) }
      let_it_be(:audit_event_2) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: 3.days.ago) }
      let_it_be(:audit_event_3) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: Date.current) }

      it_behaves_like 'audit events date filter'
    end

    context 'signed in as a developer' do
      before do
        project.add_developer(pete)
        sign_in(pete)
      end

      describe 'filter by author' do
        let_it_be(:audit_event_1) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: Date.today, ip_address: '1.1.1.1', author_id: pete.id) }
        let_it_be(:audit_event_2) { create(:project_audit_event, entity_type: 'Project', entity_id: project.id, created_at: Date.today, ip_address: '0.0.0.0', author_id: user.id) }
        let_it_be(:author) { user }

        it_behaves_like 'audit events author filtering without entity admin permission'
      end
    end
  end
end
