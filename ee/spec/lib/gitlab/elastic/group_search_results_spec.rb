# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::GroupSearchResults, :elastic do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:guest) { create(:user).tap { |u| group.add_user(u, Gitlab::Access::GUEST) } }

  let(:filters) { {} }
  let(:query) { '*' }

  subject(:results) { described_class.new(user, query, group.projects.pluck_primary_key, group: group, filters: filters) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'issues search', :sidekiq_inline do
    let!(:project) { create(:project, :public, group: group) }
    let!(:closed_result) { create(:issue, :closed, project: project, title: 'foo closed') }
    let!(:opened_result) { create(:issue, :opened, project: project, title: 'foo opened') }
    let!(:confidential_result) { create(:issue, :confidential, project: project, title: 'foo confidential') }

    let(:query) { 'foo' }
    let(:scope) { 'issues' }

    before do
      project.add_developer(user)

      ensure_elasticsearch_index!
    end

    include_examples 'search results filtered by state'
    include_examples 'search results filtered by confidential'
  end

  context 'merge_requests search', :sidekiq_inline do
    let!(:project) { create(:project, :public, group: group) }
    let!(:opened_result) { create(:merge_request, :opened, source_project: project, title: 'foo opened') }
    let!(:closed_result) { create(:merge_request, :closed, source_project: project, title: 'foo closed') }

    let(:query) { 'foo' }
    let(:scope) { 'merge_requests' }

    include_examples 'search results filtered by state' do
      before do
        ensure_elasticsearch_index!
      end
    end
  end

  context 'blobs' do
    let!(:project) { create(:project, :public, :repository, group: group) }

    it_behaves_like 'search results filtered by language'
  end

  context 'query performance' do
    include_examples 'does not hit Elasticsearch twice for objects and counts', %w[projects notes blobs wiki_blobs commits issues merge_requests milestones]
    include_examples 'does not load results for count only queries', %w[projects notes blobs wiki_blobs commits issues merge_requests milestones]
  end
end
