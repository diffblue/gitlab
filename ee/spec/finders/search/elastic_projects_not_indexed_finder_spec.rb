# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ElasticProjectsNotIndexedFinder, :elastic, :sidekiq_inline, feature_category: :global_search do
  describe '.execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be_with_reload(:project_no_repository) { create(:project) }
    let_it_be_with_reload(:project_empty_repository) { create(:project, :empty_repo) }

    subject(:execute) { described_class.execute }

    context 'when on GitLab.com', :saas do
      it 'raises an error' do
        expect { execute }.to raise_error('This cannot be run on GitLab.com')
      end
    end

    context 'when projects missing from index' do
      it 'returns an active record collection of missing projects' do
        expect(execute).to match_array([project, project_no_repository, project_empty_repository])
      end

      context 'when elasticsearch_limit_indexing? is enabled' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'only returns non-indexed projects that are enabled for indexing' do
          create(:elasticsearch_indexed_project, project: project_no_repository)

          expect(execute).to match_array([project_no_repository])
        end
      end
    end

    context 'when all projects are indexed' do
      before do
        create(:index_status, project: project)
        create(:index_status, project: project_no_repository)
        create(:index_status, project: project_empty_repository)
      end

      it 'returns an empty collection' do
        expect(execute).to be_empty
      end
    end
  end
end
