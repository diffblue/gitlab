# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Zoekt::SearchableRepository, :zoekt, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:unindexed_project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:unindexed_repository) { unindexed_project.repository }
  let_it_be(:private_project) { create(:project, :repository) }
  let(:private_repository) { private_project.repository }

  before do
    zoekt_ensure_project_indexed!(project)
  end

  describe '#use_zoekt?' do
    it 'is true for indexed projects' do
      expect(repository.use_zoekt?).to eq(true)
    end

    it 'is false for unindexed projects' do
      expect(unindexed_repository.use_zoekt?).to eq(false)
    end

    it 'is false for private projects' do
      expect(private_repository.use_zoekt?).to eq(false)
    end
  end

  def search_for(term)
    ::Gitlab::Zoekt::SearchResults.new(user, term, :any).objects('blobs').map(&:path)
  end

  describe '#update_zoekt_index!' do
    it 'makes updates available' do
      project.repository.create_file(
        user,
        'somenewsearchablefile.txt',
        'some content',
        message: 'added test file',
        branch_name: project.default_branch)

      expect(search_for('somenewsearchablefile.txt')).to be_empty

      repository.update_zoekt_index!

      expect(search_for('somenewsearchablefile.txt')).to match_array(['somenewsearchablefile.txt'])
    end
  end

  describe '.truncate_zoekt_index!' do
    it 'removes all data from the Zoekt shard' do
      expect(search_for('.')).not_to be_empty

      Repository.truncate_zoekt_index!(::Zoekt::Shard.last)

      expect(search_for('.')).to be_empty
    end
  end

  describe '#async_update_zoekt_index', :sidekiq_inline do
    it 'makes updates available via ::Zoekt::IndexerWorker' do
      expect(::Zoekt::IndexerWorker).to receive(:perform_async).with(project.id).and_call_original

      project.repository.create_file(
        user,
        'anothernewsearchablefile.txt',
        'some content',
        message: 'added test file',
        branch_name: project.default_branch)

      expect(search_for('anothernewsearchablefile.txt')).to be_empty

      repository.async_update_zoekt_index

      expect(search_for('anothernewsearchablefile.txt')).to match_array(['anothernewsearchablefile.txt'])
    end
  end
end
