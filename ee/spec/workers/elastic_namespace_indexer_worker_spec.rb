# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticNamespaceIndexerWorker, feature_category: :global_search do
  subject { described_class.new }

  context 'when ES is disabled' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: false)
      stub_ee_application_setting(elasticsearch_limit_indexing: false)
    end

    it 'returns true' do
      expect(Elastic::ProcessInitialBookkeepingService).not_to receive(:backfill_projects!)

      expect(subject.perform(1, "index")).to be_truthy
    end
  end

  context 'when ES is enabled', :elastic, :clean_gitlab_redis_shared_state do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
      stub_ee_application_setting(elasticsearch_limit_indexing: true)
    end

    it 'returns true if limited indexing is not enabled' do
      stub_ee_application_setting(elasticsearch_limit_indexing: false)

      expect(Elastic::ProcessInitialBookkeepingService).not_to receive(:backfill_projects!)

      expect(subject.perform(1, "index")).to be_truthy
    end

    describe 'indexing and deleting' do
      let_it_be(:namespace) { create :namespace }

      let(:projects) { create_list :project, 3, namespace: namespace }

      it 'indexes all projects belonging to the namespace' do
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(*projects)

        subject.perform(namespace.id, :index)
      end

      it 'deletes all projects belonging to the namespace' do
        args = projects.map { |project| [project.id, project.es_id] }
        expect(ElasticDeleteProjectWorker).to receive(:bulk_perform_async).with(args)

        subject.perform(namespace.id, :delete)
      end
    end
  end
end
