# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::UserClassProxy, feature_category: :global_search do
  subject { described_class.new(User) }

  let(:query) { 'bob' }
  let(:response) do
    Elasticsearch::Model::Response::Response.new(User, Elasticsearch::Model::Searching::SearchRequest.new(User, '*'))
  end

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe '#elastic_search' do
    it 'calls ApplicationClassProxy.search once' do
      expect(subject).to receive(:search).once

      subject.elastic_search(query)
    end

    describe 'methods being called' do
      before do
        allow(subject).to receive(:search).and_return(response)
      end

      it 'calls fuzzy_query, namespace_query and forbidden_states_filter' do
        expect(subject).to receive(:fuzzy_query).once
        expect(subject).to receive(:namespace_query).once
        expect(subject).to receive(:forbidden_states_filter).once

        subject.elastic_search(query)
      end

      describe 'query' do
        let(:fuzzy_query_result) { instance_double(Array) }
        let(:forbidden_states_query_result) { instance_double(Array) }
        let(:namespace_query_result) { fuzzy_query_result }

        before do
          allow(subject).to receive(:fuzzy_query).and_return(fuzzy_query_result)
          allow(subject).to receive(:forbidden_states_filter).and_return(forbidden_states_query_result)
          allow(subject).to receive(:namespace_query).and_return(namespace_query_result)
        end

        it 'builds a bool query with musts and filters' do
          query_hash = {
            query: {
              bool: {
                must: fuzzy_query_result,
                filter: forbidden_states_query_result
              }
            }
          }

          expect(subject).to receive(:search).with(query_hash, any_args).once

          subject.elastic_search(query)
        end

        context 'with count_only passed in arguments' do
          it 'builds a bool query with filters only and size is 0' do
            query_hash = {
              query: {
                bool: {
                  must: [],
                  filter: forbidden_states_query_result
                }
              },
              size: 0
            }

            expect(subject).to receive(:search).with(query_hash, any_args).once

            subject.elastic_search(query, options: { count_only: true })
          end
        end
      end
    end
  end

  describe '#fuzzy_query' do
    let(:query_hash) do
      subject.fuzzy_query(clauses: musts, query: query, search_fields: fuzzy_search_fields, options: options)
    end

    let(:musts) { [] }
    let(:query) { nil }
    let(:fuzzy_search_fields) { described_class::FUZZY_SEARCH_FIELDS }
    let(:options) { {} }

    it 'returns musts if no query is passed' do
      expect(query_hash).to eq(musts)
    end

    context 'when a query is passed' do
      let(:query) { 'bob' }

      it 'has 3 fuzzy queries' do
        expect(query_hash.count).to eq(1)
        fuzzy_query = query_hash.first

        expect(fuzzy_query).to have_key(:bool)
        expect(fuzzy_query[:bool]).to have_key(:should)
        expect(fuzzy_query[:bool][:should].count).to eq(3)

        fuzzy_keys = fuzzy_query[:bool][:should].map { |s| s[:fuzzy].keys }.flatten
        expect(fuzzy_keys).to match_array([:name, :username, :public_email])
      end

      context 'when the user is an admin' do
        let(:options) { { admin: true } }

        it 'has an extra fuzzy query for email' do
          expect(query_hash.count).to eq(1)
          fuzzy_query = query_hash.first

          expect(fuzzy_query).to have_key(:bool)
          expect(fuzzy_query[:bool]).to have_key(:should)
          expect(fuzzy_query[:bool][:should].count).to eq(4)

          fuzzy_keys = fuzzy_query[:bool][:should].map { |s| s[:fuzzy].keys }.flatten
          expect(fuzzy_keys).to match_array([:name, :username, :public_email, :email])
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
      expect(filter_query[:term]).to eq({ in_forbidden_state: false })
    end

    context 'when the user is an admin' do
      let(:options) { { admin: true } }

      it 'returns filters so that users are returned regardless of state' do
        expect(query_hash).to eq(filters)
      end
    end
  end
end
