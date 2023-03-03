# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProcessInitialBookkeepingService, feature_category: :global_search do
  let(:project) { create(:project) }
  let(:issue) { create(:issue) }

  describe '.backfill_projects!' do
    it 'calls initial project indexing' do
      expect(described_class).to receive(:maintain_indexed_associations).with(project, Elastic::ProcessInitialBookkeepingService::INDEXED_PROJECT_ASSOCIATIONS)
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, false, { force: true })
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, true)

      described_class.backfill_projects!(project)
    end

    it 'raises an exception if non project is provided' do
      expect { described_class.backfill_projects!(issue) }.to raise_error(ArgumentError)
    end

    it 'uses a separate queue' do
      expect { described_class.backfill_projects!(project) }.not_to change { Elastic::ProcessBookkeepingService.queue_size }
    end
  end
end
