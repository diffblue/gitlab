# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::ProjectSearchResults, :elastic do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:query) { 'hello world' }
  let(:repository_ref) { nil }
  let(:filters) { {} }

  subject(:results) { described_class.new(user, query, project: project, repository_ref: repository_ref, filters: filters) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  describe 'initialize with empty ref' do
    let(:repository_ref) { '' }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq('master') }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:repository_ref) { 'refs/heads/test' }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(repository_ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe "search", :sidekiq_inline do
    let(:project) { create(:project, :public, :repository, :wiki_repo) }
    let(:private_project) { create(:project, :repository, :wiki_repo) }

    before do
      [project, private_project].each do |p|
        create(:note, note: 'bla-bla term', project: p)
        p.wiki.create_page('index_page', 'term')
        p.wiki.index_wiki_blobs
        p.repository.index_commits_and_blobs
      end

      ensure_elasticsearch_index!
    end

    it "returns correct amounts" do
      result = described_class.new(user, 'term', project: project)
      expect(result.notes_count).to eq(1)
      expect(result.wiki_blobs_count).to eq(1)
      expect(result.blobs_count).to eq(1)

      result = described_class.new(user, 'initial', project: project)
      expect(result.commits_count).to eq(1)
    end

    context 'visibility checks' do
      let(:query) { 'term' }

      before do
        project.add_guest(user)
      end

      it 'shows wiki for guests' do
        expect(results.wiki_blobs_count).to eq(1)
      end
    end

    context 'filtering' do
      let!(:project) { create(:project, :public, :repository) }
      let(:query) { 'foo' }

      context 'issues' do
        let!(:closed_result) { create(:issue, :closed, project: project, title: 'foo closed') }
        let!(:opened_result) { create(:issue, :opened, project: project, title: 'foo opened') }
        let!(:confidential_result) { create(:issue, :confidential, project: project, title: 'foo confidential') }
        let(:scope) { 'issues' }

        before do
          project.add_developer(user)

          ensure_elasticsearch_index!
        end

        include_examples 'search results filtered by state'
        include_examples 'search results filtered by confidential'
      end

      context 'merge_requests' do
        let!(:opened_result) { create(:merge_request, :opened, source_project: project, title: 'foo opened') }
        let!(:closed_result) { create(:merge_request, :closed, source_project: project, title: 'foo closed') }
        let(:scope) { 'merge_requests' }

        before do
          ensure_elasticsearch_index!
        end

        include_examples 'search results filtered by state'
      end

      context 'blobs' do
        it_behaves_like 'search results filtered by language'
      end
    end
  end

  describe 'confidential issues', :sidekiq_might_not_need_inline do
    include_examples 'access restricted confidential issues' do
      before do
        ensure_elasticsearch_index!
      end
    end
  end

  context 'query performance' do
    let(:project) { create(:project, :public, :repository, :wiki_repo) }
    let(:query) { '*' }

    before do
      # wiki_blobs method checks to see if there is a wiki page before doing
      # the search
      create(:wiki_page, wiki: project.wiki)
    end

    include_examples 'does not hit Elasticsearch twice for objects and counts', %w[notes blobs wiki_blobs commits issues merge_requests milestones]
    include_examples 'does not load results for count only queries', %w[notes blobs wiki_blobs commits issues merge_requests milestones]
  end

  describe '#aggregations' do
    using RSpec::Parameterized::TableSyntax

    let(:results) { described_class.new(user, query, project: project) }

    subject(:aggregations) { results.aggregations(scope) }

    where(:scope, :should_return_aggregations) do
      'milestones'     | false
      'notes'          | false
      'issues'         | false
      'merge_requests' | false
      'wiki_blobs'     | false
      'commits'        | false
      'users'          | false
      'unknown'        | false
      'blobs'          | true
    end

    with_them do
      context 'when feature flag is enabled for user' do
        before do
          stub_feature_flags(search_blobs_language_aggregation: user)
        end

        it_behaves_like 'loads aggregations'
      end

      context 'when feature flag is disabled for user' do
        before do
          stub_feature_flags(search_blobs_language_aggregation: false)
        end

        it_behaves_like 'does not load aggregations'
      end
    end

    context 'project search specific gates for blob scope' do
      let(:scope) { 'blobs' }

      context 'when query is blank' do
        let(:query) { nil }

        it 'returns the an empty array' do
          expect(subject).to match_array([])
        end
      end

      context 'when project has an empty repository' do
        it 'returns an empty array' do
          allow(project).to receive(:empty_repo?).and_return(true)

          expect(subject).to match_array([])
        end
      end

      context 'when user does not have download_code permission on project' do
        it 'returns an empty array' do
          allow(Ability).to receive(:allowed?).with(user, :download_code, project).and_return(false)

          expect(subject).to match_array([])
        end
      end
    end
  end
end
