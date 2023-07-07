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
      expect(Elastic::ProcessBookkeepingService).not_to receive(:maintain_indexed_group_associations!)

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
      let_it_be(:group) { create(:group) }
      let(:projects) { create_list :project, 3, namespace: namespace }

      it 'indexes all projects belonging to the namespace' do
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(*projects)

        subject.perform(namespace.id, :index)
      end

      it 'calls Elastic::ProcessBookkeepingService.maintain_indexed_group_associations! for group namespaces' do
        expect(Elastic::ProcessBookkeepingService).to receive(:maintain_indexed_group_associations!).with(*group).once

        subject.perform(group.id, :index)
      end

      it 'does not call maintain_indexed_group_associations! for non-group namespaces' do
        expect(Elastic::ProcessBookkeepingService).not_to receive(:maintain_indexed_group_associations!)

        subject.perform(namespace.id, :index)
      end

      it 'deletes all projects belonging to the namespace' do
        args = projects.map { |project| [project.id, project.es_id] }
        expect(ElasticDeleteProjectWorker).to receive(:bulk_perform_async).with(args)

        subject.perform(namespace.id, :delete)
      end

      it 'does not enqueue Search::ElasticGroupAssociationDeletionWorker' do
        expect(Search::ElasticGroupAssociationDeletionWorker).not_to receive(:perform_async)

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

        context 'when the namespace is a group' do
          let_it_be(:parent_group) { create(:group) }
          let_it_be(:group) { create(:group, parent: parent_group) }
          let_it_be(:child_group) { create(:group, parent: group) }
          let_it_be(:another_group) { create(:group) }

          it 'enqueues GroupAssociationDeletionWorker for the group and its descendents but not for other groups' do
            expect(Search::ElasticGroupAssociationDeletionWorker).to receive(:perform_in)
              .with(elastic_group_association_deletion_worker_random_delay_range, group.id, parent_group.id)
            expect(Search::ElasticGroupAssociationDeletionWorker).to receive(:perform_in)
              .with(elastic_group_association_deletion_worker_random_delay_range, child_group.id, parent_group.id)

            expect(Search::ElasticGroupAssociationDeletionWorker).not_to receive(:perform_in)
              .with(anything, parent_group.id, parent_group.id)
            expect(Search::ElasticGroupAssociationDeletionWorker).not_to receive(:perform_in)
              .with(anything, another_group.id, parent_group.id)

            subject.perform(group.id, :delete)
          end

          it 'enqueues Search::ElasticGroupAssociationDeletionWorker for group namespaces and its descendents' do
            parent_group = create(:group)
            group = create(:group, parent: parent_group)
            child_group = create(:group, parent: group)
            another_group = create(:group)

            expect(Search::ElasticGroupAssociationDeletionWorker).to receive(:perform_in)
              .with(elastic_group_association_deletion_worker_random_delay_range, child_group.id, parent_group.id).once
            expect(Search::ElasticGroupAssociationDeletionWorker).to receive(:perform_in)
              .with(elastic_group_association_deletion_worker_random_delay_range, group.id, parent_group.id).once

            expect(Search::ElasticGroupAssociationDeletionWorker).not_to receive(:perform_in)
              .with(anything, parent_group.id, anything)
            expect(Search::ElasticGroupAssociationDeletionWorker).not_to receive(:perform_in)
              .with(anything, another_group.id, anything)

            subject.perform(group.id, :delete)
          end
        end
      end
    end
  end
end
