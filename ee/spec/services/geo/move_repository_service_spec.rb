# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::MoveRepositoryService, :geo, feature_category: :geo_replication do
  describe '#execute' do
    let(:project) { create(:project, :repository, :wiki_repo, :legacy_storage) }
    let(:old_path) { project.full_path }
    let(:new_path) { "#{project.full_path}+renamed" }
    let(:gitlab_shell) { Gitlab::Shell.new }

    subject(:service) { described_class.new(project, old_path, new_path) }

    it 'renames the project repositories' do
      old_repository = project.repository.raw
      old_wiki_repository = project.wiki.repository.raw
      new_repository = Gitlab::Git::Repository.new(project.repository.storage, "#{new_path}.git", nil, nil)
      new_wiki_repository = Gitlab::Git::Repository.new(project.repository.storage, "#{new_path}.wiki.git", nil, nil)

      expect(old_repository).to exist
      expect(old_wiki_repository).to exist

      expect(service.execute).to eq(true)

      expect(old_repository).not_to exist
      expect(old_wiki_repository).not_to exist
      expect(new_repository).to exist
      expect(new_wiki_repository).to exist
    end

    it 'returns false when project repository can not be renamed' do
      allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
        .with(project.repository_storage, old_path, new_path)
        .and_return(false)

      expect(service).to receive(:log_error).with('Repository cannot be moved')

      expect(service.execute).to eq false
    end

    it 'returns false when wiki repository can not be renamed' do
      allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
        .with(project.repository_storage, old_path, new_path)
        .and_return(true)

      allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
        .with(project.repository_storage, "#{old_path}.wiki", "#{new_path}.wiki")
        .and_return(false)

      expect(service).to receive(:log_error).with('Wiki repository cannot be moved')

      expect(service.execute).to eq false
    end

    context 'when design repository exists' do
      before do
        project.design_repository.create_if_not_exists
      end

      it 'returns false when design repository can not be renamed' do
        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, old_path, new_path)
          .and_return(true)

        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, "#{old_path}.wiki", "#{new_path}.wiki")
          .and_return(true)

        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, "#{old_path}.design", "#{new_path}.design")
          .and_return(false)

        expect(service).to receive(:log_error).with('Design repository cannot be moved')

        expect(service.execute).to eq false
      end
    end

    context 'wiki disabled' do
      let(:project) { create(:project, :repository, :wiki_disabled, :legacy_storage) }

      it 'tries to move wiki even if it is not enabled without reporting error' do
        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, old_path, new_path)
          .and_return(true)

        allow_any_instance_of(Gitlab::Shell).to receive(:mv_repository)
          .with(project.repository_storage, "#{old_path}.wiki", "#{new_path}.wiki")
          .and_return(false)

        expect(service).not_to receive(:log_error)

        expect(service.execute).to eq(true)
      end
    end
  end
end
