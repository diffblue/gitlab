# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateRepositoryStorageService, feature_category: :subgroups do
  subject { described_class.new(repository_storage_move) }

  describe "#execute" do
    let_it_be_with_reload(:group) { create(:group, :wiki_repo) }

    let(:wiki) { group.wiki }
    let(:checksum) { wiki.repository.checksum }
    let(:destination) { 'test_second_storage' }
    let(:repository_storage_move_state) { :scheduled }
    let(:repository_storage_move) { create(:group_repository_storage_move, repository_storage_move_state, container: group, destination_storage_name: destination) }
    let(:wiki_repository_double) { double(:repository) }
    let(:original_wiki_repository_double) { double(:repository) }

    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with(destination).and_return(SecureRandom.uuid)
      allow(Gitlab::Git::Repository).to receive(:new).and_call_original
      allow(Gitlab::Git::Repository).to receive(:new)
        .with(destination, wiki.repository.raw.relative_path, wiki.repository.gl_repository, wiki.repository.full_path)
        .and_return(wiki_repository_double)
      allow(Gitlab::Git::Repository).to receive(:new)
        .with('default', wiki.repository.raw.relative_path, nil, nil)
        .and_return(original_wiki_repository_double)
    end

    context 'when the move succeeds' do
      it 'moves the repository to the new storage and unmarks the repository as read-only', :aggregate_failures do
        expect(wiki_repository_double).to receive(:replicate)
          .with(wiki.repository.raw)
        expect(wiki_repository_double).to receive(:checksum)
          .and_return(checksum)
        expect(original_wiki_repository_double).to receive(:remove)

        result = subject.execute
        group.reload

        expect(result).to be_success
        expect(group).not_to be_repository_read_only
        expect(wiki.repository_storage).to eq(destination)
        expect(group.group_wiki_repository.shard_name).to eq(destination)
      end
    end

    context 'when the filesystems are the same' do
      before do
        expect(Gitlab::GitalyClient).to receive(:filesystem_id).twice.and_return(SecureRandom.uuid)
      end

      it 'updates the database without trying to move the repostory', :aggregate_failures do
        result = subject.execute
        group.reload

        expect(result).to be_success
        expect(group).not_to be_repository_read_only
        expect(wiki.repository_storage).to eq(destination)
        expect(group.group_wiki_repository.shard_name).to eq(destination)
      end
    end

    context 'when the move fails' do
      it 'unmarks the repository as read-only without updating the repository storage' do
        expect(wiki_repository_double).to receive(:replicate)
          .with(wiki.repository.raw)
          .and_raise(Gitlab::Git::CommandError)

        expect do
          subject.execute
        end.to raise_error(Gitlab::Git::CommandError)

        expect(group.reload).not_to be_repository_read_only
        expect(wiki.repository_storage).to eq('default')
        expect(repository_storage_move).to be_failed
      end
    end

    context 'when the cleanup fails' do
      it 'sets the correct state' do
        expect(wiki_repository_double).to receive(:replicate)
          .with(wiki.repository.raw)
        expect(wiki_repository_double).to receive(:checksum)
          .and_return(checksum)
        expect(original_wiki_repository_double).to receive(:remove)
          .and_raise(Gitlab::Git::CommandError)

        expect do
          subject.execute
        end.to raise_error(Gitlab::Git::CommandError)

        expect(repository_storage_move).to be_cleanup_failed
      end
    end

    context 'when the checksum does not match' do
      it 'unmarks the repository as read-only without updating the repository storage' do
        expect(wiki_repository_double).to receive(:replicate)
          .with(wiki.repository.raw)
        expect(wiki_repository_double).to receive(:checksum)
          .and_return('not matching checksum')

        expect do
          subject.execute
        end.to raise_error(UpdateRepositoryStorageMethods::Error, /Failed to verify wiki repository checksum from \w+ to not matching checksum/)

        expect(group).not_to be_repository_read_only
        expect(wiki.repository_storage).to eq('default')
      end
    end

    context 'when the repository move is finished' do
      let(:repository_storage_move_state) { :finished }

      it 'is idempotent' do
        expect do
          result = subject.execute

          expect(result).to be_success
        end.not_to change(repository_storage_move, :state)
      end
    end

    context 'when the repository move is failed' do
      let(:repository_storage_move_state) { :failed }

      it 'is idempotent' do
        expect do
          result = subject.execute

          expect(result).to be_success
        end.not_to change(repository_storage_move, :state)
      end
    end
  end
end
