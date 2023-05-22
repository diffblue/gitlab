# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic index', feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:parent_group) { create(:group) }
  let_it_be_with_refind(:group) { create(:group, parent: parent_group) }
  let_it_be_with_refind(:epic) { create(:epic, group: group) }
  let_it_be(:member) { create(:group_member, :owner, group: group, user: user) }
  let(:epic_index) { Epic.__elasticsearch__.index_name }
  let(:helper) { Gitlab::Elastic::Helper.default }
  let(:client) { helper.client }

  before do
    stub_feature_flags(elastic_index_epics: true)
    allow(::Elastic::DataMigrationService).to receive(:migration_has_finished?)
      .with(:create_epic_index).and_return(true)
    stub_ee_application_setting(elasticsearch_indexing: true)
    allow(::Elastic::ProcessBookkeepingService).to receive(:track!)
  end

  shared_examples 'epics get tracked in Elasticsearch' do
    it 'use_elasticsearch? is true' do
      expect(epic).to be_use_elasticsearch
    end

    context 'when an epic is created' do
      let(:epic) { build(:epic, group: group) }

      it 'tracks the epic' do
        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).with(epic).once
        epic.save!
      end
    end

    context 'when an epic is updated' do
      it 'tracks the epic' do
        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).with(epic).once
        epic.update!(title: 'A new title')
      end
    end

    context 'when an epic is deleted' do
      it 'tracks the epic' do
        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).with(epic).once
        epic.destroy!
      end

      it 'deletes the epic from elasticsearch', :elastic_clean do
        allow(::Elastic::ProcessBookkeepingService).to receive(:track!).and_call_original

        epic = create(:epic, group: group)
        ensure_elasticsearch_index!
        expect(epics_in_index).to eq([epic.id])

        epic.destroy!

        ensure_elasticsearch_index!
        expect(epics_in_index).to be_empty
      end
    end
  end

  shared_examples 'epics do not get tracked in Elasticsearch' do
    it 'use_elasticsearch? is false' do
      expect(epic).not_to be_use_elasticsearch
    end

    context 'when an epic is created' do
      let(:epic) { build(:epic, group: group) }

      it 'does not track the epic' do
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!).with(epic)
        epic.save!
      end
    end

    context 'when an epic is updated' do
      it 'does not track the epic' do
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!).with(epic)
        epic.update!(title: 'A new title')
      end
    end

    context 'when an epic is deleted' do
      it 'does not track the epic' do
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!).with(epic)
        epic.destroy!
      end
    end
  end

  it_behaves_like 'epics get tracked in Elasticsearch'

  context 'when elasticsearch_limit_indexing? is true' do
    before do
      stub_ee_application_setting(elasticsearch_limit_indexing?: true)
    end

    context 'if the parent group is not in the limited indexes list' do
      it_behaves_like 'epics do not get tracked in Elasticsearch'
    end

    context 'if the parent group is in the limited indexes list' do
      before do
        create(:elasticsearch_indexed_namespace, namespace: parent_group)
      end

      it_behaves_like 'epics get tracked in Elasticsearch'
    end
  end

  def epics_in_index
    client.search(index: epic_index).dig('hits', 'hits').map { |hit| hit['_source']['id'] }
  end
end
