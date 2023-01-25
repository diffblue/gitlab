# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::GlobalService, feature_category: :global_search do
  include SearchResultHelpers
  include ProjectHelpers
  include UserHelpers

  let_it_be(:user) { create(:user) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it_behaves_like 'EE search service shared examples', ::Gitlab::SearchResults, ::Gitlab::Elastic::SearchResults do
    let(:scope) { nil }
    let(:service) { described_class.new(user, params) }
  end

  context 'has_parent usage', :elastic do
    shared_examples 'search does not use has_parent' do |scope|
      let(:results) { described_class.new(nil, search: '*').execute.objects(scope) }
      let(:es_host) { Gitlab::CurrentSettings.elasticsearch_url[0] }
      let(:search_url) { Addressable::Template.new("#{es_host}/{index}/_search{?params*}") }

      it 'does not use joins to apply permissions' do
        request = a_request(:post, search_url).with do |req|
          expect(req.body).not_to include("has_parent")
        end

        results

        expect(request).to have_been_made
      end
    end

    it_behaves_like 'search does not use has_parent', 'merge_requests'
    it_behaves_like 'search does not use has_parent', 'issues'
    it_behaves_like 'search does not use has_parent', 'notes'
  end

  context 'when projects search has an empty search term', :elastic do
    subject { service.execute.objects('projects') }

    let(:service) { described_class.new(nil, search: nil) }

    it 'does not raise exception' do
      is_expected.to be_empty
    end
  end

  context 'visibility', :elastic_delete_by_query, :sidekiq_inline do
    include_context 'ProjectPolicyTable context'

    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, namespace: group) }
    let(:projects) { [project] }

    let(:user) { create_user_from_membership(project, membership) }

    context 'merge request' do
      let!(:merge_request) { create :merge_request, target_project: project, source_project: project }
      let(:scope) { 'merge_requests' }
      let(:search) { merge_request.title }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it_behaves_like 'search respects visibility'
      end
    end

    context 'note' do
      let(:scope) { 'notes' }
      let(:search) { note.note }

      context 'on issues' do
        let!(:note) { create :note_on_issue, project: project }
        let!(:confidential_note) do
          note_author_and_assignee = user || project.creator
          issue = create(:issue, project: project, assignees: [note_author_and_assignee])
          create(:note, confidential: true, project: project, noteable: issue, author: note_author_and_assignee )
        end

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_notes_feature_access
        end

        with_them do
          it_behaves_like 'search respects visibility'
        end
      end

      context 'on merge requests' do
        let!(:note) { create :note_on_merge_request, project: project }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_reporter_feature_access
        end

        with_them do
          it_behaves_like 'search respects visibility'
        end
      end

      context 'on commits' do
        let_it_be_with_reload(:project) { create(:project, :repository, namespace: group) }

        let!(:note) { create :note_on_commit, project: project }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_guest_feature_access_and_non_private_project_only
        end

        with_them do
          before do
            project.repository.index_commits_and_blobs
          end

          it_behaves_like 'search respects visibility'
        end
      end

      context 'on snippets' do
        let!(:note) { create :note_on_project_snippet, project: project }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_guest_feature_access
        end

        with_them do
          it_behaves_like 'search respects visibility'
        end
      end
    end

    context 'issue' do
      let(:scope) { 'issues' }
      let(:search) { issue.title }

      let!(:issue) { create :issue, project: project }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it_behaves_like 'search respects visibility'
      end
    end

    context 'wiki' do
      let_it_be_with_reload(:project) { create(:project, :wiki_repo) }

      let(:scope) { 'wiki_blobs' }
      let(:search) { 'term' }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        before do
          project.wiki.create_page('test.md', "# #{search}")
          project.wiki.index_wiki_blobs
        end

        it_behaves_like 'search respects visibility'
      end
    end

    context 'milestone' do
      let!(:milestone) { create :milestone, project: project }

      where(:project_level, :issues_access_level, :merge_requests_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_milestone_access
      end

      with_them do
        it "respects visibility" do
          enable_admin_mode!(user) if admin_mode
          project.update!(
            visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s),
            issues_access_level: issues_access_level,
            merge_requests_access_level: merge_requests_access_level
          )
          ensure_elasticsearch_index!

          expect_search_results(user, 'milestones', expected_count: expected_count) do |user|
            described_class.new(user, search: milestone.title).execute
          end
        end
      end
    end

    context 'project' do
      where(:project_level, :membership, :expected_count) do
        permission_table_for_project_access
      end

      with_them do
        it "respects visibility" do
          project.update!(visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s))

          ElasticCommitIndexerWorker.new.perform(project.id)
          ensure_elasticsearch_index!

          expected_objects = expected_count == 1 ? [project] : []

          expect_search_results(
            user,
            'projects',
            expected_count: expected_count,
            expected_objects: expected_objects
          ) do |user|
            described_class.new(user, search: project.name).execute
          end
        end
      end
    end
  end

  context 'sorting', :elastic, :sidekiq_inline do
    context 'issue' do
      let_it_be_with_reload(:project) { create(:project, :public) }

      let(:scope) { 'issues' }

      let!(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:issue, project: project, title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:issue, project: project, title: 'updated very old', updated_at: 1.year.ago) }

      before do
        ensure_elasticsearch_index!
      end

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(nil, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(nil, search: 'updated', sort: sort).execute }
      end
    end

    context 'merge request' do
      let_it_be_with_reload(:project) { create(:project, :public) }

      let(:scope) { 'merge_requests' }

      let!(:old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'old-1', title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:merge_request, :opened, source_project: project, source_branch: 'new-1', title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'very-old-1', title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-old-1', title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-new-1', title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-very-old-1', title: 'updated very old', updated_at: 1.year.ago) }

      before do
        ensure_elasticsearch_index!
      end

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(nil, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(nil, search: 'updated', sort: sort).execute }
      end
    end
  end

  describe '#allowed_scopes' do
    context 'when ES is used' do
      it 'includes ES-specific scopes' do
        expect(described_class.new(user, {}).allowed_scopes).to include('commits')
      end
    end

    context 'when elasticearch_search is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_search: false)
      end

      it 'does not include ES-specific scopes' do
        expect(described_class.new(user, {}).allowed_scopes).not_to include('commits')
      end
    end

    context 'when elasticsearch_limit_indexing is enabled' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      context 'when advanced_global_search_for_limited_indexing feature flag is disabled' do
        before do
          stub_feature_flags(advanced_global_search_for_limited_indexing: false)
        end

        it 'does not include ES-specific scopes' do
          expect(described_class.new(user, {}).allowed_scopes).not_to include('commits')
        end
      end

      context 'when advanced_global_search_for_limited_indexing feature flag is enabled' do
        it 'includes ES-specific scopes' do
          expect(described_class.new(user, {}).allowed_scopes).to include('commits')
        end
      end
    end
  end

  describe '#elastic_projects' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:another_project) { create(:project) }
    let_it_be(:non_admin_user) { create_user_from_membership(project, :developer) }
    let_it_be(:admin) { create(:admin) }

    let(:service) { described_class.new(user, {}) }
    let(:elastic_projects) { service.elastic_projects }

    context 'when the user is an admin' do
      let(:user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns :any' do
          expect(elastic_projects).to eq(:any)
        end
      end

      context 'when admin mode is disabled' do
        it 'returns empty array' do
          expect(elastic_projects).to eq([])
        end
      end
    end

    context 'when the user is not an admin' do
      let(:user) { non_admin_user }

      it 'returns the projects the user has access to' do
        expect(elastic_projects).to eq([project.id])
      end
    end

    context 'when there is no user' do
      let(:user) { nil }

      it 'returns empty array' do
        expect(elastic_projects).to eq([])
      end
    end
  end

  context 'confidential notes' do
    let_it_be(:project) { create(:project, :public, :repository) }

    context 'with notes on issues' do
      let(:noteable) { create(:issue, project: project) }

      it_behaves_like 'search confidential notes shared examples', :note_on_issue
    end
  end
end
