# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ProfileSchedules::Audit::UpdateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_profile_schedule) { create(:dast_profile_schedule, owner: user) }

  describe '#execute' do
    it 'creates audit events for the changed properties', :aggregate_failures do
      auditor = described_class.new(project: project, current_user: user, params: {
        dast_profile_schedule: dast_profile_schedule,
        new_params: { starts_at: Date.tomorrow },
        old_params: { starts_at: Date.today }
      })

      auditor.execute

      audit_event = AuditEvent.find_by(author_id: user.id)
      expect(audit_event.author).to eq(user)
      expect(audit_event.entity).to eq(project)
      expect(audit_event.target_id).to eq(dast_profile_schedule.id)
      expect(audit_event.target_type).to eq('Dast::ProfileSchedule')
      expect(audit_event.details).to eq({
        author_name: user.name,
        author_class: user.class.name,
        custom_message: "Changed DAST profile schedule starts_at from #{Date.today} to #{Date.tomorrow}",
        target_id: dast_profile_schedule.id,
        target_type: 'Dast::ProfileSchedule',
        target_details: user.name
      })
    end
  end
end
