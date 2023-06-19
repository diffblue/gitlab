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
      expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

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
      expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

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

      context 'when namespace is group' do
        let_it_be(:group_namespace) { create :group }
        let_it_be(:sub_group) { create :group, parent: group_namespace }

        it 'indexes all group wikis belonging to the namespace' do
          [group_namespace, sub_group].each do |group|
            expect(ElasticWikiIndexerWorker).to receive(:perform_in).with(
              elastic_wiki_indexer_worker_random_delay_range, group.id, group.class.name, { force: true })
          end

          subject.perform(group_namespace.id, :index)
        end

        it 'deletes all group wikis belonging to the namespace' do
          [group_namespace, sub_group].each do |group|
            expect(Search::Wiki::ElasticDeleteGroupWikiWorker).to receive(:perform_in).with(
              elastic_delete_group_wiki_worker_random_delay_range, group.id)
          end

          subject.perform(group_namespace.id, :delete)
        end
      end
    end
  end
end
