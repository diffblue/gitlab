# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ProjectClassProxy, feature_category: :global_search do
  subject { described_class.new(Project) }

  let(:query) { 'blob' }
  let(:options) { {} }
  let(:elastic_search) { subject.elastic_search(query, options: options) }
  let(:request) { Elasticsearch::Model::Searching::SearchRequest.new(Project, '*') }
  let(:response) do
    Elasticsearch::Model::Response::Response.new(Project, request)
  end

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe '#elastic_search' do
    describe 'query', :elastic_delete_by_query do
      it 'has the correct named queries' do
        elastic_search.response

        assert_named_queries(
          'project:match:search_terms',
          'doc:is_a:project',
          'project:archived:false'
        )
      end

      context 'when project_ids is set' do
        let(:options) { { project_ids: [create(:project).id] } }

        it 'has the correct named queries' do
          elastic_search.response

          assert_named_queries(
            'project:match:search_terms',
            'doc:is_a:project',
            'project:membership:id',
            'project:archived:false'
          )
        end
      end

      context 'when the search_projects_hide_archived feature flag is disabled' do
        before do
          stub_feature_flags(search_projects_hide_archived: false)
        end

        it 'does not have a filter for archived' do
          elastic_search.response

          assert_named_queries(
            'project:match:search_terms',
            'doc:is_a:project'
          )
        end
      end

      context 'when include_archived is set' do
        let(:options) { { include_archived: true } }

        it 'does not have a filter for archived' do
          elastic_search.response

          assert_named_queries(
            'project:match:search_terms',
            'doc:is_a:project'
          )
        end
      end
    end
  end
end
