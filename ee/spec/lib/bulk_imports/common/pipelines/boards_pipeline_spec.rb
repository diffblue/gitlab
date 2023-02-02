# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::BoardsPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:filepath) { 'ee/spec/fixtures/bulk_imports/gz/boards.ndjson.gz' }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      group: group,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Group',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:tmpdir) { Dir.mktmpdir }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
    FileUtils.copy_file(filepath, File.join(tmpdir, 'boards.ndjson.gz'))
    group.add_owner(user)
  end

  subject { described_class.new(context) }

  describe '#run' do
    it 'imports group boards into destination group and removes tmpdir' do
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
      allow_next_instance_of(BulkImports::FileDownloadService) do |service|
        allow(service).to receive(:execute)
      end

      expect { subject.run }.to change(Board, :count).by(2)

      lists = group.boards.find_by(name: 'first board').lists
      board_one = group.boards.find_by(name: 'first board')
      board_two = group.boards.find_by(name: 'second board')

      expect(lists.map(&:list_type)).to contain_exactly('assignee', 'milestone')
      expect(board_one.milestone).to be_nil
      expect(board_two.milestone.title).to eq 'v4.0'
    end
  end
end
