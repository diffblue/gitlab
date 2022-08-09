# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Profiles::Audit::UpdateService do
  let_it_be(:dast_profile) { create(:dast_profile) }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    it 'creates audit events for the changed properties', :aggregate_failures do
      auditor = described_class.new(container: project, current_user: user, params: {
        dast_profile: dast_profile,
        new_params: { name: 'New name' },
        old_params: { name: 'Old name' }
      })

      auditor.execute

      audit_event = AuditEvent.find_by(author_id: user.id)
      expect(audit_event.author).to eq(user)
      expect(audit_event.entity).to eq(project)
      expect(audit_event.target_id).to eq(dast_profile.id)
      expect(audit_event.target_type).to eq('Dast::Profile')
      expect(audit_event.target_details).to eq(dast_profile.name)
      expect(audit_event.details).to eq({
        author_name: user.name,
        author_class: user.class.name,
        custom_message: 'Changed DAST profile name from Old name to New name',
        target_id: dast_profile.id,
        target_type: 'Dast::Profile',
        target_details: dast_profile.name
      })
    end

    it 'uses names instead of IDs for the changed scanner and site profile messages' do
      new_scanner_profile = create(:dast_scanner_profile)
      old_scanner_profile = create(:dast_scanner_profile)
      new_site_profile = create(:dast_site_profile)
      old_site_profile = create(:dast_site_profile)

      auditor = described_class.new(container: project, current_user: user, params: {
        dast_profile: dast_profile,
        new_params: { dast_scanner_profile_id: new_scanner_profile.id, dast_site_profile_id: new_site_profile.id },
        old_params: { dast_scanner_profile_id: old_scanner_profile.id, dast_site_profile_id: old_site_profile.id }
      })

      auditor.execute

      audit_events = AuditEvent.where(author_id: user.id)
      messages = audit_events.map(&:details).pluck(:custom_message)
      expect(messages).to contain_exactly(
        "Changed DAST profile dast_scanner_profile from #{old_scanner_profile.name} to #{new_scanner_profile.name}",
        "Changed DAST profile dast_site_profile from #{old_site_profile.name} to #{new_site_profile.name}"
      )
    end

    it 'does not exceed the maximum permitted number of queries' do
      new_scanner_profile = create(:dast_scanner_profile)
      old_scanner_profile = create(:dast_scanner_profile)
      new_site_profile = create(:dast_site_profile)
      old_site_profile = create(:dast_site_profile)

      new_params = {
        branch_name: 'new-branch',
        dast_scanner_profile_id: new_scanner_profile.id,
        dast_site_profile_id: new_site_profile.id,
        description: 'New description',
        name: 'New name'
      }
      old_params = {
        branch_name: 'old-branch',
        dast_scanner_profile_id: old_scanner_profile.id,
        dast_site_profile_id: old_site_profile.id,
        description: 'Old description',
        name: 'Old name'
      }

      auditor = described_class.new(container: project, current_user: user, params: {
        dast_profile: dast_profile, new_params: new_params, old_params: old_params
      })

      recorder = ActiveRecord::QueryRecorder.new do
        auditor.execute
      end

      expect(recorder.count).to be <= 21
    end
  end
end
