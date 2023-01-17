# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::GroupSearchResults, :elastic do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:guest) { create(:user).tap { |u| group.add_member(u, Gitlab::Access::GUEST) } }

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

  describe 'users' do
    let(:query) { 'john' }
    let(:scope) { 'users' }
    let(:results) { described_class.new(user, query, group: group) }

    it 'returns an empty list' do
      create_list(:user, 3, name: "Sarah John")

      ensure_elasticsearch_index!

      users = results.objects('users')

      expect(users).to eq([])
      expect(results.users_count).to eq 0
    end

    context 'with group members' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:child_group) { create(:group, parent: group) }
      let_it_be(:child_of_parent_group) { create(:group, parent: parent_group) }
      let_it_be(:project_in_group) { create(:project, namespace: group) }
      let_it_be(:project_in_child_group) { create(:project, namespace: child_group) }
      let_it_be(:project_in_parent_group) { create(:project, namespace: parent_group) }
      let_it_be(:project_in_child_of_parent_group) { create(:project, namespace: child_of_parent_group) }

      it 'returns matching users who have access to the group' do
        users = create_list(:user, 8, name: "Sarah John")

        project_in_group.add_developer(users[0])
        project_in_child_group.add_developer(users[1])
        project_in_parent_group.add_developer(users[2])
        project_in_child_of_parent_group.add_developer(users[3])

        group.add_developer(users[4])
        parent_group.add_developer(users[5])
        child_group.add_developer(users[6])
        child_of_parent_group.add_developer(users[7])

        ensure_elasticsearch_index!

        expect(results.objects('users')).to contain_exactly(users[0], users[1], users[4], users[5], users[6])
        expect(results.users_count).to eq 5
      end
    end
  end

  context 'query performance' do
    include_examples 'does not hit Elasticsearch twice for objects and counts', %w[projects notes blobs wiki_blobs commits issues merge_requests milestones users]
    include_examples 'does not load results for count only queries', %w[projects notes blobs wiki_blobs commits issues merge_requests milestones users]
  end
end
