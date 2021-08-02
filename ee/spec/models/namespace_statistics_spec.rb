# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceStatistics do
  include WikiHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_wiki) do
    create(:group_wiki, group: group).tap do |group_wiki|
      group_wiki.create_page('home', 'test content')
    end
  end

  it { is_expected.to belong_to(:namespace) }

  it { is_expected.to validate_presence_of(:namespace) }

  describe '#refresh!' do
    let(:namespace) { group }
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:columns) { [] }

    subject { statistics.refresh!(only: columns) }

    context 'when database is read_only' do
      it 'does not save the object' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)

        expect(statistics).not_to receive(:save!)

        subject
      end
    end

    context 'when namespace belong to a user' do
      let(:namespace) { user.namespace }

      it 'does not save the object' do
        expect(statistics).not_to receive(:save!)

        subject
      end
    end

    shared_examples 'creates the namespace statistics' do
      specify do
        expect(statistics).to receive(:save!)

        subject
      end
    end

    context 'when invalid option is passed' do
      let(:columns) { [:foo] }

      it 'does not update any column' do
        expect(statistics).not_to receive(:update_wiki_size)

        subject
      end

      it_behaves_like 'creates the namespace statistics'
    end

    context 'when no option is passed' do
      it 'updates the wiki size' do
        expect(statistics).to receive(:update_wiki_size)

        subject
      end

      it_behaves_like 'creates the namespace statistics'
    end

    context 'when wiki_size option is passed' do
      let(:columns) { [:wiki_size] }

      it 'updates the wiki size' do
        expect(statistics).to receive(:update_wiki_size)

        subject
      end

      it_behaves_like 'creates the namespace statistics'
    end
  end

  describe '#update_storage_size' do
    let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: group) }

    it 'sets storage_size to the wiki_size' do
      statistics.wiki_size = 3

      statistics.update_storage_size

      expect(statistics.storage_size).to eq 3
    end
  end

  describe '#update_wiki_size' do
    let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: group) }

    subject { statistics.update_wiki_size }

    context 'when group_wikis feature is not enabled' do
      it 'does not update the wiki size' do
        stub_group_wikis(false)

        subject

        expect(statistics.wiki_size).to be_zero
      end
    end

    context 'when group_wikis feature is enabled enabled' do
      before do
        stub_group_wikis(true)
      end

      it 'updates the wiki size' do
        subject

        expect(statistics.wiki_size).to eq group.wiki.repository.size.megabytes.to_i
      end

      context 'when namespace does not belong to a group' do
        let(:statistics) { create(:namespace_statistics, namespace: user.namespace) }

        it 'does not update the wiki size' do
          expect(statistics).not_to receive(:wiki)

          subject

          expect(statistics.wiki_size).to be_zero
        end
      end
    end
  end

  context 'before saving statistics' do
    let(:statistics) { create(:namespace_statistics, namespace: group, wiki_size: 10) }

    it 'updates storage size' do
      expect(statistics).to receive(:update_storage_size).and_call_original

      statistics.save!

      expect(statistics.storage_size).to eq 10
    end
  end

  context 'after saving statistics', :aggregate_failures do
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:namespace) { group }

    context 'when storage_size is not updated' do
      it 'does not enqueue the job to update root storage statistics' do
        expect(statistics).not_to receive(:update_root_storage_statistics)
        expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

        statistics.save!
      end
    end

    context 'when storage_size is updated' do
      before do
        # we have to update this value instead of `storage_size` because the before_save
        # hook we have. If we don't do it, storage_size will be set to the wiki_size value
        # which is 0.
        statistics.wiki_size = 10
      end

      it 'enqueues the job to update root storage statistics' do
        expect(statistics).to receive(:update_root_storage_statistics).and_call_original
        expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group.id)

        statistics.save!
      end

      context 'when namespace does not belong to a group' do
        let(:namespace) { user.namespace }

        it 'does not enqueue the job to update root storage statistics' do
          expect(statistics).to receive(:update_root_storage_statistics).and_call_original
          expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

          statistics.save!
        end
      end
    end

    context 'when other columns are updated' do
      it 'does not enqueue the job to update root storage statistics' do
        columns_to_update = NamespaceStatistics.columns_hash.except('id', 'namespace_id', 'wiki_size', 'storage_size').keys
        columns_to_update.each { |c| statistics[c] = 10 }

        expect(statistics).not_to receive(:update_root_storage_statistics)
        expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

        statistics.save!
      end
    end
  end

  context 'after destroy statistics', :aggregate_failures do
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:namespace) { group }

    it 'enqueues the job to update root storage statistics' do
      expect(statistics).to receive(:update_root_storage_statistics).and_call_original
      expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group.id)

      statistics.destroy!
    end

    context 'when namespace belongs to a group' do
      let(:namespace) { user.namespace }

      it 'does not enqueue the job to update root storage statistics' do
        expect(statistics).to receive(:update_root_storage_statistics).and_call_original
        expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

        statistics.destroy!
      end
    end
  end
end
