# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::GroupSearchResults, :elastic, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:guest) { create(:user).tap { |u| group.add_member(u, Gitlab::Access::GUEST) } }

  let(:filters) { {} }
  let(:query) { '*' }

  subject(:results) { described_class.new(user, query, group.projects.pluck_primary_key, group: group, filters: filters) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    stub_licensed_features(epics: true)
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
    include_examples 'search results filtered by labels'
  end

  context 'merge_requests search', :sidekiq_inline do
    let!(:project) { create(:project, :public, group: group) }
    let_it_be(:unarchived_project) { create(:project, :public, group: group) }
    let_it_be(:archived_project) { create(:project, :public, :archived, group: group) }
    let!(:opened_result) { create(:merge_request, :opened, source_project: project, title: 'foo opened') }
    let!(:closed_result) { create(:merge_request, :closed, source_project: project, title: 'foo closed') }
    let!(:unarchived_result) { create(:merge_request, source_project: unarchived_project, title: 'foo unarchived') }
    let!(:archived_result) { create(:merge_request, source_project: archived_project, title: 'foo archived') }

    let(:query) { 'foo' }
    let(:scope) { 'merge_requests' }

    before do
      set_elasticsearch_migration_to(:backfill_archived_on_merge_requests, including: true)
      ensure_elasticsearch_index!
    end

    include_examples 'search results filtered by state'
    include_examples 'search results filtered by archived', 'search_merge_requests_hide_archived_projects'
  end

  context 'blobs' do
    let!(:project) { create(:project, :public, :repository, group: group) }

    it_behaves_like 'search results filtered by language'
  end

  context 'for commits', :sidekiq_inline do
    let_it_be(:owner) { create(:user) }
    let_it_be(:unarchived_project) { create(:project, :public, :repository, group: group, creator: owner) }
    let_it_be(:archived_project) { create(:project, :archived, :repository, :public, group: group, creator: owner) }

    let_it_be(:unarchived_result_object) do
      unarchived_project.repository.create_file(owner, 'test.rb', '# foo bar', message: 'foo bar', branch_name: 'master')
    end

    let_it_be(:archived_result_object) do
      archived_project.repository.create_file(owner, 'test.rb', '# foo', message: 'foo', branch_name: 'master')
    end

    let(:unarchived_result) { unarchived_project.commit }
    let(:archived_result) { archived_project.commit }
    let(:scope) { 'commits' }
    let(:query) { 'foo' }

    before do
      unarchived_project.repository.index_commits_and_blobs
      archived_project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!
    end

    include_examples 'search results filtered by archived', 'search_commits_hide_archived_projects'
  end

  context 'for projects' do
    let!(:unarchived_result) { create(:project, :public, group: group) }
    let!(:archived_result) { create(:project, :archived, :public, group: group) }

    let(:scope) { 'projects' }

    it_behaves_like 'search results filtered by archived', 'search_projects_hide_archived' do
      before do
        ensure_elasticsearch_index!
      end
    end
  end

  context 'epics search', :sidekiq_inline do
    let(:query) { 'foo' }
    let(:scope) { 'epics' }

    let_it_be(:public_parent_group) { create(:group, :public) }
    let_it_be(:group) { create(:group, :private, parent: public_parent_group) }
    let_it_be(:child_group) { create(:group, :private, parent: group) }
    let_it_be(:child_of_child_group) { create(:group, :private, parent: child_group) }
    let_it_be(:another_group) { create(:group, :private, parent: public_parent_group) }

    let!(:parent_group_epic) { create(:epic, group: public_parent_group, title: query) }
    let!(:group_epic) { create(:epic, group: group, title: query) }
    let!(:child_group_epic) { create(:epic, group: child_group, title: query) }
    let!(:confidential_child_group_epic) { create(:epic, :confidential, group: child_group, title: query) }
    let!(:confidential_child_of_child_epic) { create(:epic, :confidential, group: child_of_child_group, title: query) }
    let!(:another_group_epic) { create(:epic, group: another_group, title: query) }

    before do
      ensure_elasticsearch_index!
    end

    it 'returns no epics' do
      expect(results.objects('epics')).to be_empty
    end

    context 'when the user is a developer on the group' do
      before_all do
        group.add_developer(user)
      end

      it 'returns matching epics belonging to the group or its descendants, including confidential epics' do
        epics = results.objects('epics')

        expect(epics).to include(group_epic)
        expect(epics).to include(child_group_epic)
        expect(epics).to include(confidential_child_group_epic)

        expect(epics).not_to include(parent_group_epic)
        expect(epics).not_to include(another_group_epic)

        assert_named_queries(
          'epic:match:search_terms',
          'doc:is_a:epic',
          'namespace:ancestry_filter:descendants'
        )
      end

      context 'when searching from the child group' do
        it 'returns matching epics belonging to the child group, including confidential epics' do
          epics = described_class.new(user, query, [], group: child_group, filters: filters).objects('epics')

          expect(epics).to include(child_group_epic)
          expect(epics).to include(confidential_child_group_epic)

          expect(epics).not_to include(group_epic)
          expect(epics).not_to include(parent_group_epic)
          expect(epics).not_to include(another_group_epic)

          assert_named_queries(
            'epic:match:search_terms',
            'doc:is_a:epic',
            'namespace:ancestry_filter:descendants'
          )
        end
      end
    end

    context 'when the user is a guest of the child group and an owner of its child group' do
      before_all do
        child_group.add_guest(user)
      end

      it 'only returns non-confidential epics' do
        epics = described_class.new(user, query, [], group: child_group, filters: filters).objects('epics')

        expect(epics).to include(child_group_epic)
        expect(epics).not_to include(confidential_child_group_epic)

        assert_named_queries(
          'epic:match:search_terms',
          'doc:is_a:epic',
          'namespace:ancestry_filter:descendants',
          'confidential:false'
        )
      end

      context 'when the user is an owner of its child group' do
        before_all do
          child_of_child_group.add_owner(user)
        end

        it 'returns confidential epics from the child group' do
          epics = described_class.new(user, query, [], group: child_group, filters: filters).objects('epics')

          expect(epics).to include(child_group_epic)
          expect(epics).to include(confidential_child_of_child_epic)

          expect(epics).not_to include(confidential_child_group_epic)

          assert_named_queries(
            'epic:match:search_terms',
            'doc:is_a:epic',
            'namespace:ancestry_filter:descendants',
            'confidential:true',
            'groups:can:read_confidential_epics'
          )
        end
      end
    end
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

  describe '#notes' do
    let_it_be(:query) { 'foo' }
    let_it_be(:project) { create(:project, :public, namespace: group) }
    let_it_be(:archived_project) { create(:project, :public, :archived, namespace: group) }
    let_it_be(:note) { create(:note, project: project, note: query) }
    let_it_be(:note_on_archived_project) { create(:note, project: archived_project, note: query) }

    before do
      Elastic::ProcessBookkeepingService.track!(note, note_on_archived_project)
      ensure_elasticsearch_index!
    end

    context 'when migration backfill_archived_on_notes is not finished' do
      before do
        set_elasticsearch_migration_to(:backfill_archived_on_notes, including: false)
      end

      it 'includes the archived notes in the search results' do
        expect(subject.objects('notes')).to match_array([note, note_on_archived_project])
      end
    end

    context 'when feature_flag search_notes_hide_archived_projects is disabled' do
      before do
        stub_feature_flags(search_notes_hide_archived_projects: false)
      end

      it 'includes the archived notes in the search results' do
        expect(subject.objects('notes')).to match_array([note, note_on_archived_project])
      end
    end

    context 'when filters contains include_archived as true' do
      let(:filters) do
        { include_archived: true }
      end

      it 'includes the archived notes in the search results' do
        expect(subject.objects('notes')).to match_array([note, note_on_archived_project])
      end
    end

    it 'does not includes the archived notes in the search results' do
      expect(subject.objects('notes')).to match_array([note])
    end
  end

  context 'query performance' do
    include_examples 'does not hit Elasticsearch twice for objects and counts',
      %w[projects notes blobs wiki_blobs commits issues merge_requests epics milestones users]
    include_examples 'does not load results for count only queries',
      %w[projects notes blobs wiki_blobs commits issues merge_requests epics milestones users]
  end
end
