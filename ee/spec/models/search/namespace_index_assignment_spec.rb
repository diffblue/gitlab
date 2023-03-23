# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::NamespaceIndexAssignment, feature_category: :global_search do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:index) { create(:search_index, type: Search::NoteIndex) }
  let_it_be(:indexed_parent_namespace) { create(:group) }
  let_it_be(:indexed_child_namespace) { create(:group, parent: indexed_parent_namespace) }

  let(:assignment) { described_class.new(index: index, namespace: namespace) }

  describe 'validations' do
    it 'does not allow you to mark a subgroup as indexed' do
      expect do
        described_class.create!(index: index, namespace: indexed_child_namespace)
      end.to raise_error(/Only root namespaces can be assigned an index/)
    end

    it 'is valid with proper attributes' do
      expect(assignment).to be_valid
    end

    it 'is invalid when namespace is missing' do
      assignment.namespace = nil
      expect(assignment).not_to be_valid
    end

    it 'is invalid when index is missing' do
      assignment.index = nil
      expect(assignment).not_to be_valid
    end

    it 'is invalid when there is a duplicative assignment' do
      next_assignment = assignment.dup
      assignment.save!
      expect(next_assignment).not_to be_valid
      expect(next_assignment.errors.messages.fetch(:namespace_id)).to match_array([
        'violates unique constraint between [:namespace_id, :index_type]',
        'violates unique constraint between [:namespace_id, :search_index_id]'
      ])
    end
  end

  describe '.assign_index' do
    it 'calls safe_find_or_create_by! with correct arguments' do
      expect(described_class).to receive(:safe_find_or_create_by!).with(
        namespace: namespace, index_type: index.type
      ).and_call_original

      described_class.assign_index(namespace: namespace, index: index)

      record = described_class.last
      expect(record.namespace).to eq(namespace)
      expect(record.index).to eq(index)
    end
  end

  describe '.set_namespace_id_hashed' do
    it 'sets to namespace.hashed_root_namespace_id' do
      expect(assignment.namespace_id_hashed).to be_nil
      assignment.validate
      expect(assignment.namespace_id_hashed).to eq(namespace.hashed_root_namespace_id)
    end
  end

  describe '.set_namespace_id_non_nullable' do
    it 'sets to namespace id' do
      expect(assignment.namespace_id_non_nullable).to be_nil
      assignment.validate
      expect(assignment.namespace_id_non_nullable).to eq(namespace.id)
    end
  end

  describe '.set_index_type' do
    it 'sets to index type' do
      expect(assignment.index_type).to be_nil
      assignment.validate
      expect(assignment.index_type).to eq(index.type)
    end
  end
end
