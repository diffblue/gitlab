# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotation do
  let_it_be(:schedule) { create(:incident_management_oncall_schedule) }

  describe '.associations' do
    it { is_expected.to belong_to(:schedule).class_name('OncallSchedule').inverse_of(:rotations) }
    it { is_expected.to have_many(:participants).order(id: :asc).class_name('OncallParticipant').inverse_of(:rotation) }
    it { is_expected.to have_many(:active_participants).order(id: :asc).class_name('OncallParticipant').inverse_of(:rotation) }
    it { is_expected.to have_many(:users).through(:participants) }
    it { is_expected.to have_many(:participating_users).through(:active_participants).source(:user) }
    it { is_expected.to have_many(:shifts).class_name('OncallShift').inverse_of(:rotation) }

    describe '.active_participants' do
      let(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule) }
      let(:participant) { create(:incident_management_oncall_participant, rotation: rotation) }
      let(:removed_participant) { create(:incident_management_oncall_participant, :removed, rotation: rotation) }

      subject { rotation.active_participants }

      it { is_expected.to contain_exactly(participant) }
    end
  end

  describe '.validations' do
    subject { build(:incident_management_oncall_rotation, schedule: schedule, name: 'Test rotation') }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(200) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:oncall_schedule_id) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:length) }
    it { is_expected.to validate_numericality_of(:length) }
    it { is_expected.to validate_presence_of(:length_unit) }

    context 'when the oncall rotation with the same name exists' do
      before do
        create(:incident_management_oncall_rotation, schedule: schedule, name: 'Test rotation')
      end

      it 'has validation errors' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages.to_sentence).to eq('Name has already been taken')
      end
    end

    context 'with ends_at' do
      let(:starts_at) { Time.current }
      let(:ends_at) { 5.days.from_now }

      subject { build(:incident_management_oncall_rotation, schedule: schedule, starts_at: starts_at, ends_at: ends_at) }

      it { is_expected.to be_valid }

      context 'with ends_at before starts_at' do
        let(:ends_at) { 5.days.ago }

        it 'has validation errors' do
          expect(subject).to be_invalid
          expect(subject.errors.full_messages.to_sentence).to eq('Ends at must be after start')
        end
      end
    end

    describe 'active period start/end time' do
      context 'missing values' do
        before do
          allow(subject).to receive(stubbed_field).and_return('08:00')
        end

        context 'start time set' do
          let(:stubbed_field) { :active_period_start }

          it { is_expected.to validate_presence_of(:active_period_end) }
        end

        context 'end time set' do
          let(:stubbed_field) { :active_period_end }

          it { is_expected.to validate_presence_of(:active_period_start) }
        end
      end

      context 'hourly shifts' do
        subject { build(:incident_management_oncall_rotation, schedule: schedule, name: 'Test rotation', length_unit: :hours) }

        it 'raises a validation error if an active period is set' do
          subject.active_period_start = '08:00'
          subject.active_period_end = '17:00'

          expect(subject.valid?).to eq(false)
          expect(subject.errors.full_messages).to include(/Restricted shift times are not available for hourly shifts/)
        end
      end
    end
  end

  describe 'scopes' do
    describe '.in_progress' do
      subject { described_class.in_progress }

      let_it_be(:rotation_1) { create(:incident_management_oncall_rotation, schedule: schedule) }
      let_it_be(:rotation_2) { create(:incident_management_oncall_rotation, schedule: schedule, ends_at: nil) }
      let_it_be(:rotation_3) { create(:incident_management_oncall_rotation, schedule: schedule, starts_at: 1.week.from_now) }
      let_it_be(:rotation_4) { create(:incident_management_oncall_rotation, schedule: schedule, starts_at: 1.week.ago, ends_at: 6.days.ago) }

      it { is_expected.to contain_exactly(rotation_1, rotation_2) }
    end

    describe '.with_active_period' do
      subject { described_class.with_active_period }

      it { is_expected.to be_empty }

      context 'rotation has active period' do
        let(:rotation) { create(:incident_management_oncall_rotation, :with_active_period, schedule: schedule) }

        it { is_expected.to contain_exactly(rotation) }
      end
    end
  end

  describe '.for_project' do
    let_it_be(:schedule_rotation) { create(:incident_management_oncall_rotation, schedule: schedule) }
    let_it_be(:another_rotation) { create(:incident_management_oncall_rotation) }

    subject { described_class.for_project(schedule_rotation.project) }

    it { is_expected.to contain_exactly(schedule_rotation) }
  end

  describe '#shift_cycle_duration' do
    let_it_be(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule, length: 5, length_unit: :days) }

    subject { rotation.shift_cycle_duration }

    it { is_expected.to eq(5.days) }

    described_class.length_units.each_key do |unit|
      context "with a length unit of #{unit}" do
        let(:rotation) { build(:incident_management_oncall_rotation, schedule: schedule, length_unit: unit) }

        it { is_expected.to be_a(ActiveSupport::Duration) }
      end
    end
  end

  describe '#shifts_per_cycle' do
    let(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule, length: 5, length_unit: length_unit, active_period_start: active_period_start, active_period_end: active_period_end) }
    let(:length_unit) { :weeks }
    let(:active_period_start) { nil }
    let(:active_period_end) { nil }

    subject { rotation.shifts_per_cycle }

    context 'when no shift active period set up' do
      it { is_expected.to eq(1) }
    end

    context 'when hours' do
      let(:length_unit) { :hours }

      it { is_expected.to eq(1) }
    end

    context 'with shift active periods' do
      let(:active_period_start) { '08:00' }
      let(:active_period_end) { '17:00' }

      context 'weeks length unit' do
        let(:length_unit) { :weeks }

        it { is_expected.to eq(35) }
      end

      context 'days length unit' do
        let(:length_unit) { :days }

        it { is_expected.to eq(5) }
      end
    end
  end
end
