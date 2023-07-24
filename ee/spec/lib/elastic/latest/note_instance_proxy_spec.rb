# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::NoteInstanceProxy, feature_category: :global_search do
  subject { described_class.new(note) }

  describe '#as_indexed_json' do
    include ElasticsearchHelpers

    before do
      set_elasticsearch_migration_to :add_archived_to_notes, including: true
    end

    let(:result) { subject.as_indexed_json }
    let(:noteable) { note.noteable }
    let(:common_attributes) do
      {
        id: note.id,
        hashed_root_namespace_id: note.project.namespace.hashed_root_namespace_id,
        project_id: note.project_id,
        noteable_id: note.noteable_id,
        noteable_type: note.noteable_type,
        note: note.note,
        type: note.es_type,
        confidential: note.confidential,
        internal: note.internal,
        archived: note.project.archived,
        visibility_level: note.project.visibility_level,
        created_at: note.created_at,
        updated_at: note.updated_at
      }.with_indifferent_access
    end

    context 'when note is on Issue' do
      let_it_be(:note) { create(:note_on_issue) }
      let(:issue_attributes) do
        {
          issues_access_level: note.project.project_feature.access_level(noteable) || ProjectFeature::DISABLED,
          issue: { assignee_id: noteable.assignee_ids, author_id: noteable.author_id,
                   confidential: noteable.confidential }
        }
      end

      it 'serializes the object as a hash with issue properties' do
        expect(result).to match(common_attributes.merge(issue_attributes))
      end

      context 'when migration add_archived_to_notes is not finished' do
        before do
          set_elasticsearch_migration_to :add_archived_to_notes, including: false
        end

        it 'serializes the object as a hash without archived field' do
          expect(result).to match(common_attributes.except(:archived).merge(issue_attributes))
        end
      end
    end

    context 'when note is on Snippet' do
      let_it_be(:note) { create(:note_on_project_snippet) }

      it 'serializes the object as a hash with snippet properties' do
        snippets_access_level = note.project.project_feature.access_level(:snippets)
        expect(result).to match(common_attributes.merge({ snippets_access_level: snippets_access_level }))
      end
    end

    context 'when note is on Commit' do
      let_it_be(:note) { create(:note_on_commit) }

      it 'serializes the object as a hash with commit properties' do
        repository_access_level = note.project.project_feature.access_level(:repository)
        expect(result).to match(common_attributes.merge({ repository_access_level: repository_access_level }))
      end
    end

    context 'when note is on MergeRequest' do
      let_it_be(:note) { create(:note_on_merge_request) }

      it 'serializes the object as a hash with merge request properties' do
        merge_requests_access_level = note.project.project_feature.access_level(noteable)
        expect(result).to match(common_attributes.merge({ merge_requests_access_level: merge_requests_access_level }))
      end
    end
  end
end
