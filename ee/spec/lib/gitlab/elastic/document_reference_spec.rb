# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::DocumentReference, feature_category: :global_search do
  let_it_be(:issue) { create(:issue) }

  let(:project) { issue.project }

  let(:issue_as_array) { [Issue, issue.id, issue.es_id, issue.es_parent] }
  let(:issue_as_ref) { described_class.new(*issue_as_array) }
  let(:issue_as_str) { issue_as_array.join(' ') }

  let(:project_as_array) { [Project, project.id, project.es_id] }
  let(:project_as_ref) { described_class.new(*project_as_array) }
  let(:project_as_str) { project_as_array.join(delimiter) }
  let(:delimiter) { ' ' }

  describe '.build' do
    it 'builds a document for an issue' do
      expect(described_class.build(issue)).to eq(issue_as_ref)
    end

    it 'builds a document for a project' do
      expect(described_class.build(project)).to eq(project_as_ref)
    end
  end

  describe '.serialize' do
    it 'does nothing to a string' do
      expect(described_class.serialize('foo')).to eq('foo')
    end

    it 'serializes a DocumentReference' do
      expect(described_class.serialize(issue_as_ref)).to eq(issue_as_str)
    end

    it 'defers to serialize_record for ApplicationRecord instances' do
      expect(described_class).to receive(:serialize_record).with(issue)

      described_class.serialize(issue)
    end

    it 'defers to serialize_array for Array instances' do
      expect(described_class).to receive(:serialize_array).with(issue_as_array)

      described_class.serialize(issue_as_array)
    end

    it 'fails to serialize an unrecognised value' do
      expect { described_class.serialize(1) }.to raise_error(described_class::InvalidError)
    end
  end

  describe '.serialize_record' do
    it 'serializes an issue' do
      expect(described_class.serialize(issue)).to eq(issue_as_str)
    end

    it 'serializes a project' do
      expect(described_class.serialize(project)).to eq(project_as_str)
    end
  end

  describe '.serialize_array' do
    it 'serializes a project array' do
      expect(described_class.serialize(project_as_array)).to eq(project_as_str)
    end

    it 'serializes an issue array' do
      expect(described_class.serialize(issue_as_array)).to eq(issue_as_str)
    end

    it 'fails to serialize a too-small array' do
      expect { described_class.serialize(project_as_array[0..1]) }.to raise_error(described_class::InvalidError)
    end

    it 'fails to serialize a too-large array' do
      expect { described_class.serialize(project_as_array * 2) }.to raise_error(described_class::InvalidError)
    end
  end

  describe '.deserialize' do
    it 'deserializes an issue string' do
      expect(described_class.deserialize(issue_as_str)).to eq(issue_as_ref)
    end

    it 'deserializes a project string' do
      expect(described_class.deserialize(project_as_str)).to eq(project_as_ref)
    end

    context 'when a pipe delimiter is used' do
      let(:delimiter) { '|' }

      it 'deserializes string correctly' do
        expect(described_class.deserialize(project_as_str)).to eq(project_as_ref)
        expect(described_class.deserialize(issue_as_str)).to eq(issue_as_ref)
      end
    end
  end

  describe '#initialize' do
    it 'creates an issue reference' do
      expect(described_class.new(*issue_as_array)).to eq(issue_as_ref)
    end

    it 'creates a project reference' do
      expect(described_class.new(*project_as_array)).to eq(project_as_ref)
    end
  end

  describe '#==' do
    let(:subclass) { Class.new(described_class) }

    it 'is equal to itself' do
      expect(issue_as_ref).to eq(issue_as_ref)
    end

    it 'is equal to another ref when all elements match' do
      expect(issue_as_ref).to eq(described_class.new(*issue_as_array))
    end

    it 'is not equal unless the other instance class matches' do
      expect(issue_as_ref).not_to eq(subclass.new(*issue_as_array))
    end

    it 'is not equal unless db_id matches' do
      other = described_class.new(Issue, issue.id + 1, issue.es_id, issue.es_parent)

      expect(issue_as_ref).not_to eq(other)
    end

    it 'is not equal unless es_id matches' do
      other = described_class.new(Issue, issue.id, 'Other es_id', issue.es_parent)

      expect(issue_as_ref).not_to eq(other)
    end

    it 'is not equal unless es_parent matches' do
      other = described_class.new(Issue, issue.id, issue.es_id, 'Other es_parent')

      expect(issue_as_ref).not_to eq(other)
    end
  end

  describe '#klass_name' do
    it { expect(issue_as_ref.klass_name).to eq('Issue') }
  end

  describe '#database_record' do
    it 'returns an issue' do
      expect(issue_as_ref.database_record).to eq(issue)
    end

    it 'returns a project' do
      expect(project_as_ref.database_record).to eq(project)
    end

    it 'returns nil if the record cannot be found' do
      ref = described_class.new(Issue, issue.id + 1, 'issue_1')

      expect(ref.database_record).to be_nil
    end

    it 'raises if the class is bad' do
      ref = described_class.new(Integer, 1, 'integer_1')

      expect { ref.database_record }.to raise_error(NoMethodError)
    end
  end

  describe '#serialize' do
    it 'serializes an issue' do
      expect(issue_as_ref.serialize).to eq(issue_as_str)
    end

    it 'serializes a project' do
      expect(project_as_ref.serialize).to eq(project_as_str)
    end
  end

  describe '::Collection' do
    it 'contains a collection of DocumentReference' do
      ref1 = described_class.new(Integer, 1, 'integer_1')
      ref2 = described_class.new(Integer, 1, 'integer_1')
      ref3 = described_class.new(Integer, 1, 'integer_1')

      collection = described_class::Collection.new
      collection.deserialize_and_add(ref1.serialize)
      collection.deserialize_and_add(ref2.serialize)
      collection.deserialize_and_add(ref3.serialize)

      expect(collection.count).to eq(3)
      expect(collection.first).to eq(ref1)
    end

    describe '#preload_database_records' do
      let_it_be(:issue1) { create(:issue) }
      let_it_be(:issue2) { create(:issue) }
      let_it_be(:note1) { create(:note) }
      let_it_be(:note2) { create(:note) }
      let_it_be(:note_deleted) do
        note = create(:note)
        note.delete
        note
      end

      let_it_be(:issue_ref1) { described_class.new(Issue, issue1.id, issue1.es_id, issue1.es_parent) }
      let_it_be(:issue_ref2) { described_class.new(Issue, issue2.id, issue2.es_id, issue2.es_parent) }
      let_it_be(:note_ref1) { described_class.new(Note, note1.id, note1.es_id, note1.es_parent) }
      let_it_be(:note_ref2) { described_class.new(Note, note2.id, note2.es_id, note2.es_parent) }
      let_it_be(:note_ref_deleted) do
        described_class.new(Note, note_deleted.id, note_deleted.es_id, note_deleted.es_parent)
      end

      it 'preloads database records to avoid N+1 queries' do
        collection = described_class::Collection.new
        collection.deserialize_and_add(issue_ref1.serialize)
        collection.deserialize_and_add(note_ref1.serialize)

        control = ActiveRecord::QueryRecorder.new { collection.preload_database_records.map(&:database_record) }

        collection = described_class::Collection.new
        collection.deserialize_and_add(issue_ref1.serialize)
        collection.deserialize_and_add(note_ref1.serialize)
        collection.deserialize_and_add(issue_ref2.serialize)
        collection.deserialize_and_add(note_ref2.serialize)
        collection.deserialize_and_add(note_ref_deleted.serialize)

        database_records = nil
        expect do
          database_records = collection.preload_database_records.map { |ref| ref.database_record }
        end.not_to exceed_query_limit(control)

        expect(database_records[0]).to eq(issue1)
        expect(database_records[1]).to eq(note1)
        expect(database_records[2]).to eq(issue2)
        expect(database_records[3]).to eq(note2)
        expect(database_records[4]).to eq(nil) # Deleted database record will be nil
      end

      it 'batches database records to avoid sql timeouts' do
        stub_const("#{described_class.name}::PRELOAD_BATCH_SIZE", 2)

        note3 = create(:note)
        note_ref3 = described_class.new(Note, note3.id, note3.es_id, note3.es_parent)

        collection = described_class::Collection.new
        collection.deserialize_and_add(note_ref1.serialize)
        collection.deserialize_and_add(note_ref2.serialize)

        control = ActiveRecord::QueryRecorder.new { collection.preload_database_records.map(&:database_record) }

        collection = described_class::Collection.new
        collection.deserialize_and_add(note_ref1.serialize)
        collection.deserialize_and_add(note_ref2.serialize)
        collection.deserialize_and_add(note_ref3.serialize)

        # preloading is done in batches. we use the query recorder to validate that batching
        # is occurring. this is proven by setting the batch size to a low number and verify each set of queries
        # is run for each batch
        expect do
          collection.preload_database_records.map(&:database_record)
        end.not_to exceed_query_limit(control.count * 2)
      end
    end
  end
end
