# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetRepository, :request_store, :geo, type: :model do
  include EE::GeoHelpers

  let(:node) { create(:geo_node) }

  before do
    stub_current_geo_node(node)
  end

  context 'with 3 groups, 2 projects, and 5 snippets' do
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group_1) }

    let!(:project_1) { create(:project, group: group_1) }
    let!(:project_2) { create(:project, group: group_2) }

    let!(:project_snippet_1) { create(:project_snippet, project: project_1) }
    let!(:project_snippet_2) { create(:project_snippet, project: project_2) }
    let!(:personal_snippet_1) { create(:personal_snippet) }

    let!(:snippet_repository_1) { create(:snippet_repository, snippet: project_snippet_1) }
    let!(:snippet_repository_2) { create(:snippet_repository, snippet: personal_snippet_1) }

    let!(:snippet_repository_3) { create(:snippet_repository, shard_name: 'broken') }
    let!(:snippet_repository_4) { create(:snippet_repository) }
    let!(:snippet_repository_5) { create(:snippet_repository, snippet: project_snippet_2) }

    describe '#in_replicables_for_current_secondary?' do
      it 'all returns true if all are replicated' do
        [
          snippet_repository_1,
          snippet_repository_2,
          snippet_repository_3,
          snippet_repository_4,
          snippet_repository_5
        ].each do |repository|
          expect(repository.in_replicables_for_current_secondary?).to be true
        end
      end

      context 'with selective sync by namespace' do
        before do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])
        end

        it 'returns true for snippets in the namespace' do
          expect(snippet_repository_1.in_replicables_for_current_secondary?).to be true
        end

        it 'returns true for personal snippets' do
          expect(snippet_repository_2.in_replicables_for_current_secondary?).to be true
        end

        it 'returns false for project snippets not in an included namespace' do
          expect(snippet_repository_5.in_replicables_for_current_secondary?).to be false
        end
      end

      context 'with selective sync by shard' do
        before do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])
        end

        it 'returns true for snippets in the shard' do
          expect(snippet_repository_1.in_replicables_for_current_secondary?).to be true
        end

        it 'returns false for project snippets not in an included shard' do
          expect(snippet_repository_3.in_replicables_for_current_secondary?).to be false
        end
      end
    end

    describe '#replicables_for_current_secondary' do
      it 'returns all snippet_repositories without selective sync' do
        expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
          [
            snippet_repository_1,
            snippet_repository_2,
            snippet_repository_3,
            snippet_repository_4,
            snippet_repository_5
          ])
      end

      context 'with selective sync by namespace' do
        it 'returns snippet_repositories that belong to the namespaces + personal snippets' do
          node.update!(selective_sync_type: 'namespaces', namespaces: [group_1])

          expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
            [
              snippet_repository_1,
              snippet_repository_2,
              snippet_repository_3,
              snippet_repository_4
            ])
        end
      end

      context 'with selective sync by shard' do
        it 'returns snippet_repositories that belong to the shards' do
          node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])

          expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to match_array(
            [
              snippet_repository_1,
              snippet_repository_2,
              snippet_repository_4,
              snippet_repository_5
            ])
        end
      end

      it 'returns nothing if an unrecognised selective sync type is used' do
        node.update_attribute(:selective_sync_type, 'unknown')

        expect(described_class.replicables_for_current_secondary(1..described_class.last.id)).to be_empty
      end
    end
  end

  describe '.search' do
    let_it_be(:snippet_repository1) { create(:snippet_repository) }
    let_it_be(:snippet_repository2) { create(:snippet_repository) }

    context 'when search query is empty' do
      it 'returns all records' do
        result = described_class.search('')

        expect(result).to contain_exactly(snippet_repository1, snippet_repository2)
      end
    end

    context 'when search query is not empty' do
      context 'without matches' do
        it 'filters all records' do
          result = described_class.search('something_that_does_not_exist')

          expect(result).to be_empty
        end
      end

      context 'with matches by attributes' do
        where(:searchable_attribute) { described_class::EE_SEARCHABLE_ATTRIBUTES }

        before do
          # Use update_column to bypass attribute validations like regex formatting, checksum, etc.
          snippet_repository1.update_column(searchable_attribute, 'any_keyword')
        end

        with_them do
          it do
            result = described_class.search('any_keyword')

            expect(result).to contain_exactly(snippet_repository1)
          end
        end
      end
    end
  end
end
