# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::PersistAllRotationsShiftsJob, feature_category: :incident_management do
  let(:worker) { described_class.new }

  let_it_be(:schedule) { create(:incident_management_oncall_schedule) }

  let_it_be(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule) }
  let_it_be(:rotation_2) { create(:incident_management_oncall_rotation, schedule: schedule) }
  let_it_be(:not_started_rotation) { create(:incident_management_oncall_rotation, schedule: schedule, starts_at: 1.day.from_now) }
  let_it_be(:ended_rotation) { create(:incident_management_oncall_rotation, schedule: schedule, starts_at: 5.days.ago, ends_at: 1.day.ago) }

  describe '.perform' do
    subject(:perform) { worker.perform }

    it 'creates a PersistOncallShiftsJob for each started rotation' do
      expect(::IncidentManagement::OncallRotations::PersistShiftsJob).to receive(:perform_async).with(rotation.id)
      expect(::IncidentManagement::OncallRotations::PersistShiftsJob).to receive(:perform_async).with(rotation_2.id)
      expect(::IncidentManagement::OncallRotations::PersistShiftsJob).not_to receive(:perform_async).with(not_started_rotation.id)
      expect(::IncidentManagement::OncallRotations::PersistShiftsJob).not_to receive(:perform_async).with(ended_rotation.id)

      perform
    end
  end
end
