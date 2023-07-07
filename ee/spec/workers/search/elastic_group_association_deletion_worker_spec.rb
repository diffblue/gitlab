# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ElasticGroupAssociationDeletionWorker, feature_category: :global_search do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(group.id, parent_group.id) }

    let_it_be(:parent_group) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent_group) }
    let(:epic_index) { Epic.__elasticsearch__.index_name }
    let(:helper) { Gitlab::Elastic::Helper.default }
    let(:client) { helper.client }

    context 'when indexing is paused' do
      before do
        allow(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(true)
      end

      it 'adds the job to the waiting queue' do
        expect(Elastic::IndexingControlService).to receive(:add_to_waiting_queue!)
          .with(described_class, [group.id, parent_group.id], anything).once

        perform
      end
    end

    context 'when Elasticsearch is enabled', :elastic_clean do
      before do
        stub_ee_application_setting(elasticsearch_indexing: true)
      end

      context 'when Epic indexing is avaialble' do
        before do
          allow(Epic).to receive(:elasticsearch_available?).and_return(true)
        end

        it 'deletes epics belonging to the group' do
          group_epic = create(:epic, group: group)
          create(:epic)

          ensure_elasticsearch_index!

          expect(epics_in_index.count).to eq(2)
          expect(epics_in_index).to include(group_epic.id)

          perform

          helper.refresh_index(index_name: epic_index)

          expect(epics_in_index.count).to eq(1)
          expect(epics_in_index).not_to include(group_epic.id)
        end
      end

      context 'when Epic indexing is not available' do
        it 'does not delete epics belonging to the group' do
          group_epic = create(:epic, group: group)
          create(:epic)

          allow(Epic).to receive(:elasticsearch_available?).and_return(true)
          ensure_elasticsearch_index!

          expect(epics_in_index.count).to eq(2)
          expect(epics_in_index).to include(group_epic.id)

          allow(Epic).to receive(:elasticsearch_available?).and_return(false)
          perform

          helper.refresh_index(index_name: epic_index)

          expect(epics_in_index.count).to eq(2)
          expect(epics_in_index).to include(group_epic.id)
        end
      end
    end
  end

  def epics_in_index
    client.search(index: epic_index).dig('hits', 'hits').map { |hit| hit['_source']['id'] }
  end
end
