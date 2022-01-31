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

  describe '#refresh!' do
    let(:namespace) { group }
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:columns) { [] }

    subject(:refresh!) { statistics.refresh!(only: columns) }

    shared_examples 'creates the namespace statistics' do
      specify do
        expect(statistics).to receive(:save!)

        refresh!
      end
    end

    context 'when no option is passed' do
      it 'updates the wiki size' do
        expect(statistics).to receive(:update_wiki_size)

        refresh!
      end

      it_behaves_like 'creates the namespace statistics'
    end

    context 'when wiki_size option is passed' do
      let(:columns) { [:wiki_size] }

      it 'updates the wiki size' do
        expect(statistics).to receive(:update_wiki_size)

        refresh!
      end

      it_behaves_like 'creates the namespace statistics'
    end
  end

  describe '#update_storage_size' do
    let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: group, dependency_proxy_size: 2, storage_size: 2) }

    it 'adds wiki_size to the storage_size' do
      statistics.wiki_size = 3

      statistics.update_storage_size

      expect(statistics.storage_size).to eq 5
    end
  end

  describe '#update_wiki_size' do
    let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: group) }

    subject(:update_wiki_size) { statistics.update_wiki_size }

    context 'when group_wikis feature is not enabled' do
      it 'does not update the wiki size' do
        stub_group_wikis(false)

        update_wiki_size

        expect(statistics.wiki_size).to be_zero
      end
    end

    context 'when group_wikis feature is enabled' do
      before do
        stub_group_wikis(true)
      end

      it 'updates the wiki size' do
        update_wiki_size

        expect(statistics.wiki_size).to eq group.wiki.repository.size.megabytes.to_i
      end

      context 'when namespace does not belong to a group' do
        let(:statistics) { create(:namespace_statistics, namespace: user.namespace) }

        it 'does not update the wiki size' do
          expect(statistics).not_to receive(:wiki)

          update_wiki_size

          expect(statistics.wiki_size).to be_zero
        end
      end
    end
  end
end
