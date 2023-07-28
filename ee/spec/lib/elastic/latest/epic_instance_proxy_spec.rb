# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::EpicInstanceProxy, feature_category: :global_search do
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }
  let_it_be(:label) { create(:group_label, group: group) }
  let_it_be(:epic) { create(:labeled_epic, :use_fixed_dates, :opened, group: group, labels: [label]) }

  subject { described_class.new(epic) }

  describe '#as_indexed_json' do
    let(:result) { subject.as_indexed_json.with_indifferent_access }

    it 'serializes the object as a hash' do
      expect(result).to include(
        id: epic.id,
        iid: epic.iid,
        group_id: group.id,
        created_at: epic.created_at,
        updated_at: epic.updated_at,
        title: epic.title,
        description: epic.description,
        state: 'opened',
        confidential: epic.confidential,
        author_id: epic.author_id,
        label_ids: [label.id.to_s],
        start_date: epic.start_date,
        due_date: epic.due_date,
        traversal_ids: "#{parent_group.id}-#{group.id}-",
        hashed_root_namespace_id: ::Search.hash_namespace_id(parent_group.id),
        visibility_level: group.visibility_level,
        schema_version: 2306,
        type: 'epic'
      )
    end

    it 'does not have an N+1 for building the document' do
      epic = create(:epic, group: group)

      control = ActiveRecord::QueryRecorder.new do
        epic.__elasticsearch__.as_indexed_json
      end

      group_with_parent = create(:group, :private, parent: group)
      epic.update!(group_id: group_with_parent.id)

      expect do
        epic.__elasticsearch__.as_indexed_json
      end.not_to exceed_query_limit(control.count)
    end

    context 'with start date inherited date from child epic and due date inherited from milestone' do
      let_it_be(:epic) { create(:epic) }
      let_it_be(:child_epic) { create(:epic, :use_fixed_dates) }
      let_it_be(:milestone) { create(:milestone, :with_dates) }

      before do
        epic.start_date_sourcing_epic = child_epic
        epic.due_date_sourcing_milestone = milestone
        epic.save!
      end

      it 'sets start and due dates to inherited dates' do
        expect(result[:start_date]).to eq(child_epic.start_date)
        expect(result[:due_date]).to eq(milestone.due_date)
      end
    end
  end

  describe '#es_parent' do
    it 'contains group id' do
      expect(subject.es_parent).to eq("group_#{parent_group.id}")
    end
  end
end
