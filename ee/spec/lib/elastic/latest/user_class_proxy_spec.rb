# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::UserClassProxy do
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

      it 'calls fuzzy_query, ancestry_query and forbidden_states_filter' do
        expect(subject).to receive(:fuzzy_query).once
        expect(subject).to receive(:ancestry_query).once
        expect(subject).to receive(:forbidden_states_filter).once

        subject.elastic_search(query)
      end

      describe 'query' do
        let(:fuzzy_query_result) { instance_double(Array) }
        let(:ancestry_query_result) { instance_double(Array) }
        let(:forbidden_states_query_result) { instance_double(Array) }

        before do
          allow(subject).to receive(:fuzzy_query).and_return(fuzzy_query_result)
          allow(subject).to receive(:ancestry_query).and_return(ancestry_query_result)
          allow(subject).to receive(:forbidden_states_filter).and_return(forbidden_states_query_result)
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
      end
    end
  end

  describe '#fuzzy_query' do
    let(:query_hash) do
      subject.fuzzy_query(filters: musts, query: query, search_fields: fuzzy_search_fields, options: options)
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

  describe '#ancestry_query' do
    let(:query_hash) { subject.ancestry_query(filters, options) }
    let(:filters) { [] }
    let(:options) { { current_user: user } }
    let_it_be(:user) { create(:user) }

    it 'returns filters if no groups or projects are passed in' do
      expect(query_hash).to eq(filters)
    end

    context 'with projects' do
      let_it_be(:project) { create(:project) }
      let(:options) { { current_user: user, projects: [project] } }

      it 'calls ApplicationClassProxy.ancestry_filter with the project namespace id' do
        project_namespace_ancestry = project.elastic_namespace_ancestry

        expect(project_namespace_ancestry).to eq("#{project.namespace.id}-p#{project.id}-")
        expect(subject).to receive(:ancestry_filter).with(any_args, [project_namespace_ancestry]).once

        query_hash
      end
    end

    context 'with groups' do
      let_it_be(:group) { create(:group) }
      let(:options) { { current_user: user, groups: [group] } }

      it 'calls ApplicationClassProxy.ancestry_filter with the group namespace id' do
        group_namespace_ancestry = group.elastic_namespace_ancestry

        expect(group_namespace_ancestry).to eq("#{group.id}-")
        expect(subject).to receive(:ancestry_filter).with(any_args, [group_namespace_ancestry]).once

        query_hash
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
