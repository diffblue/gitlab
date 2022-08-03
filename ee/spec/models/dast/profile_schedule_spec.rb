# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ProfileSchedule, type: :model do
  let(:dast_profile_schedule) { create(:dast_profile_schedule, project: project) }

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:inactive_dast_profile_schedule) { create(:dast_profile_schedule, active: false, project: project) }

  subject { dast_profile_schedule }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:dast_profile).class_name('Dast::Profile').required.inverse_of(:dast_profile_schedule) }
    it { is_expected.to belong_to(:owner).class_name('User').with_foreign_key(:user_id) }
  end

  describe 'validations' do
    let(:timezones) { ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.identifier } }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:timezone) }
    it { is_expected.to validate_inclusion_of(:timezone).in_array(timezones) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_uniqueness_of(:dast_profile_id) }

    describe 'cadence' do
      context 'when valid values' do
        [
          { unit: 'day',   duration: 1 },
          { unit: 'week',  duration: 1 },
          { unit: 'month', duration: 1 },
          { unit: 'month', duration: 3 },
          { unit: 'month', duration: 6 },
          { unit: 'year',  duration: 1 },
          {}
        ].each do |cadence|
          it "allows #{cadence[:unit]} values" do
            schedule = build(:dast_profile_schedule, cadence: cadence)

            expect(schedule).to be_valid
            expect(schedule.cadence).to eq(cadence.stringify_keys)
          end
        end
      end

      context 'when invalid values' do
        [
          { unit: 'day', duration: 3 },
          { unit: 'month_foo', duration: 100 }
        ].each do |cadence|
          it "disallow #{cadence[:unit]} values" do
            expect { build(:dast_profile_schedule, cadence: cadence).validate! }.to raise_error(ActiveRecord::RecordInvalid) do |err|
              expect(err.record.errors.full_messages).to include('Cadence must be a valid json schema')
            end
          end
        end
      end
    end
  end

  describe 'validate' do
    describe 'validate_plan_limit_not_exceeded_while_activating' do
      subject { build(:dast_profile_schedule, project: project, dast_profile: create(:dast_profile)) }

      let_it_be(:plan_limits) { create(:plan_limits, :default_plan) }

      context 'when the plan limit has not been exceeded' do
        before do
          create(:dast_profile_schedule, project: project, dast_profile: create(:dast_profile))
        end

        it 'can activate the schedule' do
          expect { subject.save! }.to change { described_class.count }

          subject.active = true

          expect(subject.save).to be true
        end
      end

      context 'when the plan limit has been exceeded' do
        let_it_be(:inactive_schedule) { create(:dast_profile_schedule, project: project, dast_profile: create(:dast_profile), active: false) }

        before do
          plan_limits.update!(subject.class.limit_name => 1)

          create(:dast_profile_schedule, project: create(:project), dast_profile: create(:dast_profile), active: true)
        end

        it 'prevents the schedule from being activated', :aggregate_failures do
          expect { subject.dup.save! }.to change { described_class.count }

          inactive_schedule.active = true

          expect { inactive_schedule.save! }.to raise_error(ActiveRecord::RecordInvalid).and not_change { described_class.count }
          expect(inactive_schedule.errors[:base]).to contain_exactly("Maximum number of #{inactive_schedule.class.limit_name.humanize(capitalize: false)} (1) exceeded")
        end

        it 'allows the schedule to be deactivated', :aggregate_failures do
          active_schedule = subject.dup

          expect { active_schedule.save! }.to change { described_class.count }
          expect(active_schedule.update(active: false)).to be true
        end
      end
    end
  end

  describe 'scopes' do
    describe 'active' do
      it 'includes the correct records' do
        result = described_class.active

        aggregate_failures do
          expect(result).to include(subject)
          expect(result).not_to include(inactive_dast_profile_schedule)
        end
      end
    end

    describe '.runnable_schedules' do
      subject { described_class.runnable_schedules }

      context 'when there are runnable schedules' do
        let!(:profile_schedule) do
          travel_to(2.days.ago) do
            create(:dast_profile_schedule, cadence: { unit: 'day', duration: 1 })
          end
        end

        it 'returns the runnable schedule' do
          is_expected.to eq([profile_schedule])
        end
      end

      context 'when there are inactive schedules' do
        let!(:profile_schedule) do
          travel_to(1.day.ago) do
            create(:dast_profile_schedule, active: false)
          end
        end

        it 'returns an empty array' do
          is_expected.to be_empty
        end
      end

      context 'when there are no runnable schedules' do
        let!(:profile_schedule) {}

        it 'returns an empty array' do
          is_expected.to be_empty
        end
      end

      context 'when there are runnable schedules in future' do
        let!(:profile_schedule) do
          travel_to(1.day.from_now) do
            create(:dast_profile_schedule)
          end
        end

        it 'returns an empty array' do
          is_expected.to be_empty
        end
      end
    end
  end

  describe 'before_save' do
    describe '#set_cron' do
      context 'when repeat? is true' do
        it 'sets the cron value' do
          freeze_time do
            cron_statement = Gitlab::Ci::CronParser.parse_natural_with_timestamp(subject.starts_at, subject.cadence)

            expect(subject.cron).to eq cron_statement
          end
        end
      end

      context 'when repeat? is false' do
        subject { create(:dast_profile_schedule, cadence: {}) }

        it 'sets the cron value to default when non repeating' do
          expect(subject.cron).to eq Dast::ProfileSchedule::CRON_DEFAULT
        end
      end
    end
  end

  describe '#set_next_run_at' do
    let(:schedule) { create(:dast_profile_schedule, cadence: { unit: 'day', duration: 1 }, starts_at: Time.zone.now) }
    let(:schedule_1) { create(:dast_profile_schedule, cadence: { unit: 'day', duration: 1 }) }
    let(:schedule_2) { create(:dast_profile_schedule, cadence: { unit: 'day', duration: 1 }) }

    let(:cron_worker_next_run_at) { schedule.send(:cron_worker_next_run_from, Time.zone.now) }

    context 'when schedule runs every minute' do
      it "updates next_run_at to the worker's execution time" do
        travel_to(1.day.ago) do
          expect(schedule.next_run_at.to_i).to eq(cron_worker_next_run_at.to_i)
        end
      end
    end

    context 'when there are two different schedules in the same time zones' do
      it 'sets the sames next_run_at' do
        expect(schedule_1.next_run_at.to_i).to eq(schedule_2.next_run_at.to_i)
      end
    end

    context 'when starts_at is updated for existing schedules' do
      it 'updates next_run_at automatically' do
        expect { schedule.update!(starts_at: Time.zone.now + 2.days) }.to change { schedule.next_run_at }
      end
    end
  end

  describe '#schedule_next_run!' do
    let_it_be(:plan_limits) { create(:plan_limits, :default_plan) }

    context 'when repeat? is true' do
      it 'sets active to true' do
        subject.schedule_next_run!

        expect(subject.active).to be true
      end
    end

    context 'when repeat? is false' do
      it 'sets active to false' do
        subject.update_column(:cadence, {})

        subject.schedule_next_run!

        expect(subject.active).to be false
      end
    end
  end

  describe 'limitable' do
    it_behaves_like 'includes Limitable concern' do
      subject { build(:dast_profile_schedule, project: project, dast_profile: create(:dast_profile)) }
    end
  end

  describe '#with_active_schedules' do
    subject { dast_profile_schedule.with_active_schedules }

    it 'returns only active schedules' do
      is_expected.not_to include(inactive_dast_profile_schedule)
    end
  end

  describe '#owner_valid?' do
    let_it_be(:owner) { create(:user) }

    let(:dast_profile_schedule_with_owner) { create(:dast_profile_schedule, project: project, user_id: owner.id) }

    subject { dast_profile_schedule_with_owner }

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when the scheduler owner is not null and has the ability to create_on_demand_dast_scan' do
        before do
          project.add_developer(owner)
        end

        it { is_expected.to be_owner_valid }
      end

      context 'when the user_id is nil' do
        let(:dast_profile_schedule_nil_owner) { create(:dast_profile_schedule, project: project, user_id: nil) }

        subject { dast_profile_schedule_nil_owner }

        it { is_expected.not_to be_owner_valid }
      end
    end
  end
end
