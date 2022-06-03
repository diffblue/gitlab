# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallSchedulePolicy do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:oncall_schedule) { create(:incident_management_oncall_schedule, project: project) }

  subject(:policy) { described_class.new(user, oncall_schedule) }

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  describe 'rules' do
    it { is_expected.to be_disallowed :read_incident_management_oncall_schedule }

    context 'when reporter' do
      before do
        project.add_reporter(user)
      end

      it { is_expected.to be_allowed :read_incident_management_oncall_schedule }

      context 'licensed feature disabled' do
        before do
          stub_licensed_features(oncall_schedules: false)
        end

        it { is_expected.to be_disallowed :read_incident_management_oncall_schedule }
      end
    end

    context 'when auditor' do
      let(:user) { create(:auditor) }

      it { is_expected.to be_allowed :read_incident_management_oncall_schedule }
      it { is_expected.to be_disallowed :admin_incident_management_oncall_schedule }

      context 'licensed feature disabled' do
        before do
          stub_licensed_features(oncall_schedules: false)
        end

        it { is_expected.to be_disallowed :read_incident_management_oncall_schedule }
        it { is_expected.to be_disallowed :admin_incident_management_oncall_schedule }
      end
    end
  end
end
