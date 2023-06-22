# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::UserClassProxy, feature_category: :global_search do
  subject { described_class.new(User, use_separate_indices: true) }

  let(:query) { 'bob' }
  let(:options) { {} }
  let(:elastic_search) { subject.elastic_search(query, options: options) }
  let(:response) do
    Elasticsearch::Model::Response::Response.new(User, Elasticsearch::Model::Searching::SearchRequest.new(User, '*'))
  end

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe '#elastic_search' do
    it 'calls ApplicationClassProxy.search once' do
      expect(subject).to receive(:search).once

      elastic_search
    end

    describe 'methods being called' do
      before do
        allow(subject).to receive(:search).and_return(response)
      end

      it 'calls fuzzy_query_hash, namespace_query and forbidden_states_filter' do
        expect(subject).to receive(:fuzzy_query_hash).and_call_original.once
        expect(subject).to receive(:namespace_query).and_call_original.once
        expect(subject).to receive(:forbidden_states_filter).and_call_original.once

        elastic_search
      end

      context 'when the query contains simple query string syntax characters' do
        let(:query) { 'bo*' }

        it 'calls basic_query_hash, namespace_query and forbidden_states_filter' do
          expect(subject).to receive(:basic_query_hash).and_call_original.once
          expect(subject).to receive(:namespace_query).and_call_original.once
          expect(subject).to receive(:forbidden_states_filter).and_call_original.once

          elastic_search
        end
      end
    end

    context 'when the query does not contain simple query string syntax characters', :elastic_delete_by_query do
      describe 'query' do
        it 'has fuzzy queries and filters for forbidden state' do
          elastic_search.response

          assert_named_queries(
            'must:bool:should:fuzzy:name',
            'must:bool:should:fuzzy:username',
            'must:bool:should:fuzzy:public_email',
            'filter:not_forbidden_state'
          )
        end

        context 'with admin passed in arguments' do
          let(:options) { { admin: true } }

          it 'does not have the forbidden state filter and includes email for the query search' do
            elastic_search.response

            assert_named_queries(
              'must:bool:should:fuzzy:name',
              'must:bool:should:fuzzy:username',
              'must:bool:should:fuzzy:email',
              'must:bool:should:fuzzy:public_email'
            )
          end
        end

        context 'with count_only passed in arguments' do
          let(:options) { { count_only: true } }

          it 'only has filters' do
            elastic_search.response

            assert_named_queries(
              'filter:bool:should:fuzzy:name',
              'filter:bool:should:fuzzy:username',
              'filter:bool:should:fuzzy:public_email',
              'filter:not_forbidden_state'
            )
          end
        end
      end
    end

    context 'when the query contains simple query string syntax characters', :elastic_delete_by_query do
      let(:query) { 'bo*' }

      describe 'query' do
        it 'has a simple query string and filters for forbidden state' do
          elastic_search.response

          assert_named_queries(
            'user:match:search_terms',
            'filter:not_forbidden_state'
          )
        end
      end
    end
  end

  describe '#namespace_query' do
    let(:query_hash) { subject.namespace_query(musts, options) }
    let(:musts) { [] }
    let(:options) { { current_user: user } }
    let_it_be(:user) { create(:user) }

    it 'returns musts if no groups or projects are passed in' do
      expect(query_hash).to eq(musts)
    end

    context 'with a project' do
      let_it_be(:project) { create(:project) }
      let(:options) { { current_user: user, project_id: project.id } }

      it 'has a terms query with the full ancestry and its namespace' do
        full_ancestry = "#{project.namespace.id}-p#{project.id}-"
        namespace = "#{project.namespace.id}-"

        expected_hash = { bool: { should: [{ terms: { namespace_ancestry_ids: [namespace, full_ancestry] } }] } }
        expect(query_hash).to match_array([expected_hash])
      end

      context 'when the project belongs to a group with an ancestor' do
        let_it_be(:parent_group) { create(:group) }
        let_it_be(:group) { create(:group, parent: parent_group) }

        before do
          project.namespace = group
          project.save!
        end

        it 'has a terms query with the full ancestry and individual parts of the ancestry' do
          full_ancestry = "#{parent_group.id}-#{group.id}-p#{project.id}-"
          group_ancestry = "#{parent_group.id}-#{group.id}-"
          parent_group_ancestry = "#{parent_group.id}-"

          expected_terms = [parent_group_ancestry, group_ancestry, full_ancestry]
          expected_hash = { bool: { should: [{ terms: { namespace_ancestry_ids: expected_terms } }] } }

          expect(query_hash).to match_array([expected_hash])
        end
      end
    end

    context 'with a group' do
      let_it_be(:group) { create(:group) }
      let(:options) { { current_user: user, group_id: group.id } }

      it 'has a prefix query with the group ancestry' do
        group_ancestry = "#{group.id}-"

        expected_hash = { bool: { should: [{ prefix: { namespace_ancestry_ids: { value: group_ancestry } } }] } }
        expect(query_hash).to match_array([expected_hash])
      end

      context 'when the group has a parent group' do
        let_it_be(:parent_group) { create(:group) }

        before do
          group.parent = parent_group
          group.save!
        end

        it 'has a prefix query with the group ancestry and a terms query with the parent group ancestry' do
          full_ancestry = "#{parent_group.id}-#{group.id}-"
          parent_group_ancestry = "#{parent_group.id}-"

          expected_prefix_hash = { prefix: { namespace_ancestry_ids: { value: full_ancestry } } }
          expected_terms_hash = { terms: { namespace_ancestry_ids: [parent_group_ancestry] } }

          expected_hash = { bool: { should: [expected_prefix_hash, expected_terms_hash] } }
          expect(query_hash).to match_array([expected_hash])
        end
      end
    end
  end

  describe '#forbidden_states_filter' do
    let(:query_hash) { subject.forbidden_states_filter(filters, options) }
    let(:filters) { [] }
    let(:options) { {} }

    it 'has a term with forbidden_state eq false' do
      expect(query_hash.count).to eq(1)
      filter_query = query_hash.first

      expect(filter_query).to have_key(:term)
      expect(filter_query[:term]).to include({ in_forbidden_state: hash_including(value: false) })
    end

    context 'when the user is an admin' do
      let(:options) { { admin: true } }

      it 'returns filters so that users are returned regardless of state' do
        expect(query_hash).to eq(filters)
      end
    end
  end
end
