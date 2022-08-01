# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DevopsAdoption::Snapshot, type: :model do
  it { is_expected.to belong_to(:namespace) }

  it { is_expected.to validate_presence_of(:namespace) }
  it { is_expected.to validate_presence_of(:recorded_at) }
  it { is_expected.to validate_presence_of(:end_time) }

  describe '.latest_for_namespace_ids' do
    it 'returns for previous month finalized snapshot for the given namespace ids based on snapshot end_time' do
      travel_to(Date.new(2021, 07, 15)) do
        group1 = create(:group)
        group1_latest_snapshot = create(:devops_adoption_snapshot, namespace: group1, end_time: 1.month.ago.end_of_month, recorded_at: 1.day.ago)
        create(:devops_adoption_snapshot, namespace: group1, end_time: 2.months.ago.end_of_month, recorded_at: 1.day.ago)

        group2 = create(:group)
        create(:devops_adoption_snapshot, namespace: group2, end_time: 1.year.ago.end_of_month, recorded_at: 1.day.ago)
        create(:devops_adoption_snapshot, namespace: group2, end_time: 2.years.ago.end_of_month, recorded_at: 1.day.ago)

        latest_snapshots = described_class.latest_for_namespace_ids([group1.id, group2.id])

        expect(latest_snapshots).to match_array([group1_latest_snapshot])
      end
    end
  end

  describe '.for_month' do
    it 'returns all snapshots where end_time equals given datetime end of month' do
      end_of_month = Time.zone.now.end_of_month
      snapshot1 = create(:devops_adoption_snapshot, end_time: end_of_month)
      create(:devops_adoption_snapshot, end_time: end_of_month - 1.year)

      expect(described_class.for_month(end_of_month)).to match_array([snapshot1])
      expect(described_class.for_month(end_of_month - 10.days)).to match_array([snapshot1])
      expect(described_class.for_month(end_of_month.beginning_of_month)).to match_array([snapshot1])
    end
  end

  describe '.not_finalized' do
    it 'returns all snapshots which were recorded earlier than snapshot end_time' do
      snapshot1 = create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: Time.zone.now)
      create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: 2.days.ago)

      expect(described_class.not_finalized).to match_array([snapshot1])
    end
  end

  describe '.finalized' do
    it 'returns all snapshots which were recorded later than snapshot end_time' do
      create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: Time.zone.now)
      snapshot1 = create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: 2.days.ago)

      expect(described_class.finalized).to match_array([snapshot1])
    end
  end

  describe '.for_timespan' do
    let_it_be(:first_date) { DateTime.parse('2021-05-10').end_of_month }
    let_it_be(:snapshot1) { create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: first_date) }
    let_it_be(:snapshot2) { create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: first_date + 1.month) }
    let_it_be(:snapshot3) { create(:devops_adoption_snapshot, recorded_at: 1.day.ago, end_time: first_date + 2.months) }

    it 'returns snapshots for given timespan', :aggregate_failures do
      expect(described_class.for_timespan(to: first_date + 1.week)).to match_array([snapshot1])
      expect(described_class.for_timespan(from: first_date + 1.week)).to match_array([snapshot2, snapshot3])
      expect(described_class.for_timespan(from: first_date + 1.week, to: first_date + 40.days)).to match_array([snapshot2])
    end
  end

  describe '.for_namespaces' do
    it 'returns all snapshots with given namespaces' do
      snapshot1 = create(:devops_adoption_snapshot)
      snapshot2 = create(:devops_adoption_snapshot)
      create(:devops_adoption_snapshot)

      expect(described_class.for_namespaces([snapshot1.namespace, snapshot2.namespace])).to match_array([snapshot1, snapshot2])
    end
  end

  describe '#start_time' do
    subject(:snapshot) { described_class.new(end_time: end_time) }

    let(:end_time) { DateTime.parse('2020-12-17') }
    let(:expected_start_time) { DateTime.parse('2020-12-01') }

    it 'is start of the month of end_time' do
      expect(snapshot.start_time).to eq(expected_start_time)
    end
  end
end
