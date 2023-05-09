# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProcessInitialBookkeepingService, feature_category: :global_search do
  let(:project) { create(:project) }
  let(:issue) { create(:issue) }

  describe '.backfill_projects!' do
    it 'calls ElasticCommitIndexerWorker and, ElasticWikiIndexerWorker if feature separate_elastic_wiki_indexer_for_project is enabled' do
      expect(described_class).to receive(:maintain_indexed_associations).with(project, Elastic::ProcessInitialBookkeepingService::INDEXED_PROJECT_ASSOCIATIONS)
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, false, { force: true })
      expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(project.id, project.class.name)

      described_class.backfill_projects!(project)
    end

    it 'calls only ElasticCommitIndexerWorker if feature separate_elastic_wiki_indexer_for_project is disabled' do
      stub_feature_flags(separate_elastic_wiki_indexer_for_project: false)
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
