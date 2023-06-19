# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupWiki, feature_category: :wiki do
  it_behaves_like 'wiki model' do
    let(:wiki_container) { create(:group, :wiki_repo) }
    let(:wiki_container_without_repo) { create(:group) }

    before do
      wiki_container.add_owner(user)
    end

    describe '#create_wiki_repository' do
      let(:shard) { 'foo' }

      it 'tracks the repository storage in the database' do
        # Use a custom storage shard value, to make sure we're not falling back to the default.
        allow(subject).to receive(:repository_storage).and_return(shard)
        allow(subject).to receive(:default_branch).and_return('bar')

        # Don't actually create the repository, because the storage shard doesn't exist.
        expect(subject.repository).to receive(:create_if_not_exists)
        allow(subject).to receive(:repository_exists?).and_return(true)

        expect(subject).to receive(:track_wiki_repository).with(shard)

        subject.create_wiki_repository
      end
    end

    describe '#track_wiki_repository' do
      let(:shard) { 'foo' }

      context 'when a tracking entry does not exist' do
        let(:wiki_container) { wiki_container_without_repo }

        it 'creates a new entry' do
          expect { subject.track_wiki_repository(shard) }.to change(wiki_container, :group_wiki_repository)
            .from(nil).to(kind_of(GroupWikiRepository))
        end

        it 'tracks the storage location' do
          subject.track_wiki_repository(shard)

          expect(wiki_container.group_wiki_repository).to have_attributes(
            disk_path: subject.storage.disk_path,
            shard_name: shard
          )
        end

        context 'on a read-only instance' do
          before do
            allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          end

          it 'does not attempt to create a new entry' do
            expect { subject.track_wiki_repository(shard) }.not_to change(wiki_container, :group_wiki_repository)
          end
        end
      end

      context 'when a tracking entry exists' do
        it 'does not create a new entry in the database' do
          expect { subject.track_wiki_repository(shard) }.not_to change(wiki_container, :group_wiki_repository)
        end

        it 'updates the storage location' do
          expect(subject.storage).to receive(:disk_path).and_return('fancy/new/path')

          subject.track_wiki_repository(shard)

          expect(wiki_container.group_wiki_repository).to have_attributes(
            disk_path: 'fancy/new/path',
            shard_name: shard
          )
        end

        context 'on a read-only instance' do
          before do
            allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          end

          it 'does not update the storage location' do
            allow(subject.storage).to receive(:disk_path).and_return('fancy/new/path')

            subject.track_wiki_repository(shard)

            expect(wiki_container.group_wiki_repository).not_to have_attributes(
              disk_path: 'fancy/new/path',
              shard_name: shard
            )
          end
        end
      end
    end

    describe '#storage' do
      it 'uses the group repository prefix' do
        expect(subject.storage.base_dir).to start_with('@groups/')
      end
    end

    describe '#repository_storage' do
      it 'gets the repository storage from the container' do
        expect(wiki.container).to receive(:repository_storage).and_return('foo')

        expect(subject.repository_storage).to eq 'foo'
      end
    end

    describe '#hashed_storage?' do
      it 'returns true' do
        expect(subject.hashed_storage?).to be(true)
      end
    end

    describe '#disk_path' do
      it 'returns the repository storage path' do
        expect(subject.disk_path).to eq("#{subject.storage.disk_path}.wiki")
      end
    end

    describe '#after_post_receive' do
      it 'updates group statistics' do
        expect(Groups::UpdateStatisticsWorker).to receive(:perform_async).with(wiki.container.id, [:wiki_size])

        subject.send(:after_post_receive)
      end
    end

    describe '.use_elasticsearch?' do
      it 'group should receive use_elasticsearch?' do
        expect(wiki_container).to receive(:use_elasticsearch?)
        wiki.use_elasticsearch?
      end
    end
  end

  it_behaves_like 'EE wiki model' do
    let(:wiki_container) { create(:group, :wiki_repo) }

    before do
      wiki_container.add_owner(user)
    end

    it 'does use Elasticsearch' do
      expect(subject).to be_a(Elastic::WikiRepositoriesSearch)
    end
  end

  it_behaves_like 'can housekeep repository' do
    let_it_be(:resource) { create(:group_wiki) }

    let(:resource_key) { 'group_wikis' }
    let(:expected_worker_class) { ::GroupWikis::GitGarbageCollectWorker }
  end
end
