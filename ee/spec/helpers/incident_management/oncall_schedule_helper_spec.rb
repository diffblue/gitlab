# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallScheduleHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#oncall_schedule_data' do
    subject(:data) { helper.oncall_schedule_data(project) }

    before do
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(user, :admin_incident_management_oncall_schedule, project).and_return(false)
    end

    it 'returns on-call schedule data' do
      is_expected.to eq(
        'project-path' => project.full_path,
        'empty-oncall-schedules-svg-path' => helper.image_path('illustrations/empty-state/empty-schedule-md.svg'),
        'timezones' => helper.timezone_data(format: :full).to_json,
        'escalation-policies-path' => project_incident_management_escalation_policies_path(project),
        'user_can_create_schedule' => 'false',
        'access_level_description_path' => Gitlab::Routing.url_helpers.project_project_members_url(
          project,
          sort: 'access_level_desc'
        )
      )
    end
  end
end
