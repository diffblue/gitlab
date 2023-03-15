# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::SnippetService, feature_category: :global_search do
  include SearchResultHelpers
  include ProjectHelpers
  include AdminModeHelper
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'EE search service shared examples', ::Gitlab::SnippetSearchResults, ::Gitlab::Elastic::SnippetSearchResults do
    let_it_be(:user) { create(:user) }
    let(:scope) { nil }
    let(:service) { described_class.new(user, params) }
  end

  describe '#execute' do
    include_context 'ProjectPolicyTable context'

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    context 'visibility', :elastic_delete_by_query, :clean_gitlab_redis_shared_state, :sidekiq_inline do
      include_context 'ProjectPolicyTable context'
      include ProjectHelpers

      let_it_be(:admin)          { create(:admin) }
      let_it_be(:other_user)     { create(:user) }
      let_it_be(:reporter)       { create(:user) }
      let_it_be(:guest)          { create(:user) }
      let_it_be(:snippet_author) { create(:user) }

      context 'project snippet' do
        let(:pendings) do
          # TODO: Ignore some spec cases, non-members regular users or non-member admins without admin mode should see snippets if:
          #   - feature access level is enabled, and
          #   - project access level is public or internal, and
          #   - snippet access level is equal or more open than the project access level
          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45988#note_436009204
          [
            { snippet_level: :public, project_level: :public, feature_access_level: :enabled, membership: :admin, admin_mode: false, expected_count: 1 },
            { snippet_level: :public, project_level: :internal, feature_access_level: :enabled, membership: :admin, admin_mode: false, expected_count: 1 },
            { snippet_level: :internal, project_level: :public, feature_access_level: :enabled, membership: :admin, admin_mode: false, expected_count: 1 },
            { snippet_level: :internal, project_level: :internal, feature_access_level: :enabled, membership: :admin, admin_mode: false, expected_count: 1 },
            { snippet_level: :public, project_level: :public, feature_access_level: :enabled, membership: :non_member, admin_mode: nil, expected_count: 1 },
            { snippet_level: :public, project_level: :internal, feature_access_level: :enabled, membership: :non_member, admin_mode: nil, expected_count: 1 },
            { snippet_level: :internal, project_level: :public, feature_access_level: :enabled, membership: :non_member, admin_mode: nil, expected_count: 1 },
            { snippet_level: :internal, project_level: :internal, feature_access_level: :enabled, membership: :non_member, admin_mode: nil, expected_count: 1 }
          ]
        end

        let(:pending?) do
          pendings.include?(
            {
              snippet_level: snippet_level,
              project_level: project_level,
              feature_access_level: feature_access_level,
              membership: membership,
              admin_mode: admin_mode,
              expected_count: expected_count
            }
          )
        end

        let_it_be(:group)   { create(:group) }
        let_it_be(:project, refind: true) do
          create(:project, :public, namespace: group).tap do |p|
            p.add_member(reporter, :reporter)
            p.add_member(guest, :guest)
          end
        end

        let_it_be(:snippet) { create(:project_snippet, :public, project: project, author: snippet_author, title: 'foobar') }

        where(:snippet_level, :project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_project_snippet_access
        end

        with_them do
          it 'respects visibility' do
            project.update!(visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s), snippets_access_level: feature_access_level)
            snippet.update!(visibility_level: Gitlab::VisibilityLevel.level_value(snippet_level.to_s))
            ensure_elasticsearch_index!

            expected_objects = expected_count == 0 ? [] : [snippet]

            search_user = user_from_membership(membership)
            enable_admin_mode!(search_user) if admin_mode

            expect_search_results(search_user, 'snippet_titles', expected_objects: expected_objects, pending: pending?) do |user|
              described_class.new(user, search: snippet.title).execute
            end
          end
        end
      end

      context 'personal snippet' do
        let_it_be(:public_snippet)   { create(:personal_snippet, :public, title: 'This is a public snippet', author: snippet_author) }
        let_it_be(:private_snippet)  { create(:personal_snippet, :private, title: 'This is a private snippet', author: snippet_author) }
        let_it_be(:internal_snippet) { create(:personal_snippet, :internal, title: 'This is a internal snippet', author: snippet_author) }

        let(:snippets) do
          {
            public: public_snippet,
            private: private_snippet,
            internal: internal_snippet
          }
        end

        let(:snippet) { snippets[snippet_level] }

        where(:snippet_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_personal_snippet_access
        end

        with_them do
          it 'respects visibility' do
            # When the snippets are created the ES settings are not enabled
            # and we need to manually add them to ES for indexing.
            ::Elastic::ProcessBookkeepingService.track!(snippet)
            ensure_elasticsearch_index!
            expected_objects = expected_count == 0 ? [] : [snippet]

            search_user = user_from_membership(membership)
            enable_admin_mode!(search_user) if admin_mode

            expect_search_results(search_user, 'snippet_titles', expected_objects: expected_objects) do |user|
              described_class.new(user, search: snippet.title).execute
            end
          end
        end
      end

      def user_from_membership(membership)
        case membership
        when :author
          snippet.author
        when :anonymous
          nil
        when :non_member
          other_user
        when :admin
          admin
        when :reporter
          reporter
        else
          guest
        end
      end
    end
  end
end
