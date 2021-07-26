# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallScheduleHelper do
  let_it_be(:project) { create(:project) }

  describe '#oncall_schedule_data' do
    subject(:data) { helper.oncall_schedule_data(project) }

    it 'returns on-call schedule data' do
      is_expected.to eq(
        'project-path' => project.full_path,
        'empty-oncall-schedules-svg-path' => helper.image_path('illustrations/empty-state/empty-on-call.svg'),
        'timezones' => helper.timezone_data(format: :full).to_json,
        'escalation-policies-path' => project_incident_management_escalation_policies_path(project)
      )
    end
  end
end
