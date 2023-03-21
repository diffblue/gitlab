# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repositories, feature_category: :backup_restore do
  let(:progress) { spy(:stdout) }
  let(:strategy) { spy(:strategy) }
  let(:storages) { [] }
  let(:paths) { [] }
  let(:destination) { 'repositories' }
  let(:backup_id) { 'backup_id' }

  subject { described_class.new(progress, strategy: strategy, storages: storages, paths: paths) }

  describe '#dump' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:groups) { create_list(:group, 5, :wiki_repo) }

    it 'calls enqueue for each repository type', :aggregate_failures do
      subject.dump(destination, backup_id)

      expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
      groups.each do |group|
        expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
      end
      expect(strategy).to have_received(:finish!)
    end

    describe 'command failure' do
      it 'enqueue_group raises an error' do
        allow(strategy).to receive(:enqueue).with(anything, Gitlab::GlRepository::WIKI).and_raise(IOError)

        expect { subject.dump(destination, backup_id) }.to raise_error(IOError)
      end

      it 'group query raises an error' do
        allow(Group).to receive_message_chain(:includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

        expect { subject.dump(destination, backup_id) }.to raise_error(ActiveRecord::StatementTimeout)
      end
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        subject.dump(destination, backup_id)
      end.count

      create_list(:group, 2, :wiki_repo)

      expect do
        subject.dump(destination, backup_id)
      end.not_to exceed_query_limit(control_count)
    end

    context 'storages' do
      let(:storages) { %w{default} }

      before do
        stub_storage_settings('test_second_storage' => {
          'gitaly_address' => Gitlab.config.repositories.storages.default.gitaly_address,
          'path' => TestEnv::SECOND_STORAGE_PATH
        })
      end

      it 'calls enqueue for all repositories on the specified storage', :aggregate_failures do
        excluded_group = create(:group, :wiki_repo)
        excluded_group.group_wiki_repository.update!(shard_name: 'test_second_storage')

        subject.dump(destination, backup_id)

        expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).not_to have_received(:enqueue).with(excluded_group, Gitlab::GlRepository::WIKI)
        groups.each do |group|
          expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
        end
        expect(strategy).to have_received(:finish!)
      end
    end
  end

  describe '#restore' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:group) { create(:group, :wiki_repo) }

    it 'calls enqueue for each repository type', :aggregate_failures do
      subject.restore(destination)

      expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default])
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
      expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
      expect(strategy).to have_received(:finish!)
    end

    context 'storages' do
      let(:storages) { %w{default} }

      before do
        stub_storage_settings('test_second_storage' => {
          'gitaly_address' => Gitlab.config.repositories.storages.default.gitaly_address,
          'path' => TestEnv::SECOND_STORAGE_PATH
        })
      end

      it 'calls enqueue for all repositories on the specified storage', :aggregate_failures do
        excluded_group = create(:group, :wiki_repo)
        excluded_group.group_wiki_repository.update!(shard_name: 'test_second_storage')

        subject.restore(destination)

        expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default])
        expect(strategy).not_to have_received(:enqueue).with(excluded_group, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:finish!)
      end
    end

    context 'paths' do
      let(:paths) { [group.full_path] }

      it 'calls enqueue for all descendant repositories on the specified group', :aggregate_failures do
        subject.restore(destination)

        expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: nil)
        expect(strategy).not_to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(group, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:finish!)
      end
    end
  end
end
