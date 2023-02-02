# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::EpicsPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:filepath) { 'ee/spec/fixtures/bulk_imports/gz/epics.ndjson.gz' }
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
    FileUtils.copy_file(filepath, File.join(tmpdir, 'epics.ndjson.gz'))
    stub_licensed_features(epics: true)
    group.add_owner(user)
  end

  subject { described_class.new(context) }

  describe '#run' do
    before do
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
      allow_next_instance_of(BulkImports::FileDownloadService) do |service|
        allow(service).to receive(:execute)
      end

      subject.run
    end

    it 'imports group epics into destination group' do
      expect(group.epics.count).to eq(6)
    end

    it 'imports epic award emoji' do
      expect(group.epics.first.award_emoji.first.name).to eq('thumbsup')
    end

    it 'imports epic notes' do
      expect(group.epics.first.state).to eq('opened')
      expect(group.epics.first.notes.count).to eq(4)
      expect(group.epics.first.notes.first.award_emoji.first.name).to eq('drum')
    end

    it 'imports epic labels' do
      label = group.epics.first.labels.first

      expect(group.epics.first.labels.count).to eq(1)
      expect(label.title).to eq('title')
      expect(label.description).to eq('description')
      expect(label.color).to be_color('#cd2c5c')
    end

    it 'imports epic system note metadata' do
      note = group.epics.find_by_title('system notes').notes.first

      expect(note.system).to eq(true)
      expect(note.system_note_metadata.action).to eq('relate_epic')
    end
  end

  describe '#load' do
    context 'when epic is not persisted' do
      it 'saves the epic' do
        epic = build(:epic, group: group)

        expect(epic).to receive(:save!)

        subject.load(context, epic)
      end
    end

    context 'when epic is missing' do
      it 'returns' do
        expect(subject.load(context, nil)).to be_nil
      end
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::NdjsonPipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractor' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::NdjsonExtractor,
          options: { relation: described_class.relation }
        )
    end
  end
end
