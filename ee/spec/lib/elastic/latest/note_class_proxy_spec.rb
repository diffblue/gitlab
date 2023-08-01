# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::NoteClassProxy, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  subject { described_class.new(Note, use_separate_indices: true) }

  describe '#es_type' do
    it 'returns notes' do
      expect(subject.es_type).to eq 'note'
    end
  end

  describe '#elastic_search', :elastic, :sidekiq_inline do
    let_it_be(:project) { create :project, :public }
    let_it_be(:project2) { create :project, :public }
    let_it_be(:archived_project) { create :project, :archived, :public }
    let_it_be(:user) { create :user }
    let(:result) { subject.elastic_search('test', options: options) }
    let_it_be(:note) { create(:note, note: 'test', project: project) }
    let_it_be(:note2) { create(:note, note: 'test', project: project2) }
    let_it_be(:archived_note) { create(:note, note: 'test', project: archived_project) }

    context 'when performing a global search' do
      let(:options) do
        # For global search project_ids should be empty array and public_and_internal_projects should be true
        { current_user: user, project_ids: [], public_and_internal_projects: true }
      end

      before do
        Elastic::ProcessBookkeepingService.track!(note, note2, archived_note)
        ensure_elasticsearch_index!
      end

      context 'when migration backfill_archived_on_notes is not finished' do
        before do
          set_elasticsearch_migration_to(:backfill_archived_on_notes, including: false)
        end

        it 'does not add archived filter query and includes the archived notes with results from all projects' do
          expect(elasticsearch_hit_ids(result)).to match_array [note.id, note2.id, archived_note.id]
          assert_named_queries('note:match:search_terms', without: ['note:archived:non_archived'])
        end
      end

      context 'when feature_flag search_notes_hide_archived_projects is disabled' do
        before do
          stub_feature_flags(search_notes_hide_archived_projects: false)
        end

        it 'does not add archived filter query and includes the archived notes with results from all projects' do
          expect(elasticsearch_hit_ids(result)).to match_array [note.id, note2.id, archived_note.id]
          assert_named_queries('note:match:search_terms', without: ['note:archived:non_archived'])
        end
      end

      context 'when options contains include_archived as true' do
        let(:options) do
          { current_user: user, project_ids: [], public_and_internal_projects: true, include_archived: true }
        end

        it 'does not add archived filter query and includes the archived notes with results from all projects' do
          expect(elasticsearch_hit_ids(result)).to match_array [note.id, note2.id, archived_note.id]
          assert_named_queries('note:match:search_terms', without: ['note:archived:non_archived'])
        end
      end

      it 'adds archived filter query and does not includes the archived notes in the search results' do
        expect(elasticsearch_hit_ids(result)).to match_array [note.id, note2.id]
        assert_named_queries('note:match:search_terms', 'note:archived:non_archived')
      end
    end
  end
end
