# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::IncidentManagement::OncallShifts::ReadService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:current_user) { user_with_permissions }

  let_it_be_with_refind(:rotation) { create(:incident_management_oncall_rotation, :utc, length: 1, length_unit: :days) }
  let_it_be(:participant) { create(:incident_management_oncall_participant, :with_developer_access, rotation: rotation) }
  let_it_be(:project) { rotation.project }

  let_it_be(:persisted_first_shift) { create(:incident_management_oncall_shift, participant: participant) }
  let_it_be(:first_shift) { build(:incident_management_oncall_shift, participant: participant) }
  let_it_be(:second_shift) { build(:incident_management_oncall_shift, participant: participant, starts_at: first_shift.ends_at) }
  let_it_be(:third_shift) { build(:incident_management_oncall_shift, participant: participant, starts_at: second_shift.ends_at) }

  let(:start_time) { rotation.starts_at }
  let(:end_time) { 3.days.after(start_time) }
  let(:params) { { start_time: start_time, end_time: end_time } }

  let(:service) { described_class.new(rotation, current_user, **params) }

  before_all do
    project.add_reporter(user_with_permissions)
  end

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    shared_examples 'returns expected shifts' do
      it 'successfully returns a sorted collection of IncidentManagement::OncallShifts' do
        expect(execute).to be_success

        shifts = execute.payload[:shifts]

        expect(shifts).to all(be_a(::IncidentManagement::OncallShift))
        expect(shifts.sort_by(&:starts_at)).to eq(shifts)
        expect(shifts.map(&:attributes)).to eq(expected_shifts.map(&:attributes))
      end
    end

    subject(:execute) { service.execute }

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to view shifts for this rotation'
    end

    context 'when the current_user does not have permissions to create on-call schedules' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to view shifts for this rotation'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it_behaves_like 'error response', 'Your license does not support on-call rotations'
    end

    context 'when the start time is after the end time' do
      let(:end_time) { 1.day.before(start_time) }

      it_behaves_like 'error response', '`start_time` should precede `end_time`'
    end

    context 'when timeframe exceeds one month' do
      let(:end_time) { 2.months.after(start_time) }

      it_behaves_like 'error response', '`end_time` should not exceed one month after `start_time`'
    end

    context 'when timeframe is exactly 1 month' do
      let(:start_time) { rotation.starts_at.beginning_of_day }
      let(:end_time) { 1.month.after(start_time).end_of_day }

      it { is_expected.to be_success }
    end

    context 'with time frozen' do
      around do |example|
        travel_to(current_time) { example.run }
      end

      context 'when timeframe spans the current time' do
        let(:current_time) { 5.minutes.after(start_time) }
        let(:expected_shifts) { [persisted_first_shift, second_shift, third_shift] }

        include_examples 'returns expected shifts'
      end

      context 'when timeframe is entirely in the past' do
        let(:current_time) { 5.minutes.after(end_time) }
        let(:expected_shifts) { [persisted_first_shift] }

        include_examples 'returns expected shifts'
      end

      context 'when timeframe is entirely in the future' do
        let(:current_time) { 5.minutes.before(start_time) }
        let(:expected_shifts) { [first_shift, second_shift, third_shift] }

        include_examples 'returns expected shifts'
      end
    end
  end
end
