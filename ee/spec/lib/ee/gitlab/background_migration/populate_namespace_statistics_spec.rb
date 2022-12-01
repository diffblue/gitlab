# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateNamespaceStatistics do
  include AfterNextHelpers

  let!(:namespaces) { table(:namespaces) }
  let!(:namespace_statistics) { table(:namespace_statistics) }

  let!(:group1) { namespaces.create!(id: 10, type: 'Group', name: 'group1', path: 'group1') }
  let!(:group2) { namespaces.create!(id: 20, type: 'Group', name: 'group2', path: 'group2') }
  let!(:group1_stats) { namespace_statistics.create!(id: 10, namespace_id: 10) }

  let(:repo_size) { 123456 }
  let(:expected_repo_size) { repo_size.megabytes }
  let(:ids) { namespaces.pluck(:id) }
  let(:statistics) { [] }

  subject(:perform) { described_class.new.perform(ids, statistics) }

  before do
    allow_next(Repository).to receive(:size).and_return(repo_size)
  end

  context 'when group wikis are not enabled' do
    it 'does not update wiki stats' do
      perform

      expect(namespace_statistics.where(wiki_size: 0).count).to eq 2
    end
  end

  it 'creates/updates all namespace_statistics and update root storage statistics', :aggregate_failures do
    stub_licensed_features(group_wikis: true)

    expect(namespace_statistics.count).to eq 1

    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group1.id)
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group2.id)

    perform

    expect(namespace_statistics.count).to eq 2

    namespace_statistics.all.each do |stat|
      expect(stat.wiki_size).to eq expected_repo_size
      expect(stat.storage_size).to eq expected_repo_size
    end
  end

  context 'when just a stat is passed' do
    let(:statistics) { [:wiki_size] }

    it 'calls the statistics update service with just that stat' do
      expect(Groups::UpdateStatisticsService).to receive(:new).with(anything, statistics: [:wiki_size]).twice.and_call_original

      perform
    end
  end
end
