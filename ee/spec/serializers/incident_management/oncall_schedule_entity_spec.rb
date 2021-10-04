# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallScheduleEntity do
  let(:schedule) { create(:incident_management_oncall_schedule) }
  let(:schedule_url) { Gitlab::Routing.url_helpers.project_incident_management_oncall_schedules_url(schedule.project) }
  let(:project_url) { Gitlab::Routing.url_helpers.project_url(schedule.project) }

  subject { described_class.new(schedule) }

  describe '.as_json' do
    it 'includes oncall schdule attributes' do
      attributes = subject.as_json

      expect(attributes[:name]).to eq(schedule.name)
      expect(attributes[:project_name]).to eq(schedule.project.name)
      expect(attributes[:url]).to eq(schedule_url)
      expect(attributes[:project_url]).to eq(project_url)
    end
  end
end
