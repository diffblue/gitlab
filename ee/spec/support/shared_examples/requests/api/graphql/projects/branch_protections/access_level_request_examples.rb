# frozen_string_literal: true

RSpec.shared_examples 'AccessLevel type objects contains user and group' do |access_level_kind|
  let(:protected_branch) { create(:protected_branch, default_access_level: false, project: project) }
  let(:user_access_level) { access_levels.for_user.first }
  let(:group_access_level) { access_levels.for_group.first }
  let(:user_access_level_data) { access_levels_data.find { |data| data['user'].present? } }
  let(:group_access_level_data) { access_levels_data.find { |data| data['group'].present? } }

  context 'when request AccessLevel type objects as a maintainer' do
    describe 'query' do
      include_context 'when user tracking is disabled'

      let(:fields) { all_graphql_fields_for("#{access_level_kind.to_s.classify}AccessLevel") }

      it 'avoids N+1 queries', :use_sql_query_cache, :aggregate_failures do
        create(
          "protected_branch_#{access_level_kind}_access_level",
          protected_branch: protected_branch,
          group: create(:project_group_link, project: protected_branch.project).group
        )
        create(
          "protected_branch_#{access_level_kind}_access_level",
          protected_branch: protected_branch,
          user: create(:user, developer_projects: [project])
        )

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user, variables: variables)
        end

        create(
          "protected_branch_#{access_level_kind}_access_level",
          protected_branch: protected_branch,
          group: create(:project_group_link, project: protected_branch.project).group
        )
        create(
          "protected_branch_#{access_level_kind}_access_level",
          protected_branch: protected_branch,
          user: create(:user, developer_projects: [project])
        )

        expect do
          post_graphql(query, current_user: current_user, variables: variables)
        end.not_to exceed_all_query_limit(control)
      end
    end

    describe 'response' do
      before do
        create(
          "protected_branch_#{access_level_kind}_access_level",
          protected_branch: protected_branch,
          group: create(:project_group_link, project: protected_branch.project).group
        )
        create(
          "protected_branch_#{access_level_kind}_access_level",
          protected_branch: protected_branch,
          user: create(:user, developer_projects: [project])
        )
        post_graphql(query, current_user: current_user, variables: variables)
      end

      it_behaves_like 'a working graphql query'

      it 'returns all the access level attributes' do
        expect(user_access_level_data['accessLevel']).to eq(user_access_level.access_level)
        expect(user_access_level_data['accessLevelDescription']).to eq(user_access_level.humanize)
        expect(user_access_level_data.dig('user', 'name')).to eq(user_access_level.user.name)
        expect(user_access_level_data.dig('group', 'name')).to be_nil

        expect(group_access_level_data['accessLevel']).to eq(group_access_level.access_level)
        expect(group_access_level_data['accessLevelDescription']).to eq(group_access_level.humanize)
        expect(group_access_level_data.dig('group', 'name')).to eq(group_access_level.group.name)
        expect(group_access_level_data.dig('user', 'name')).to be_nil
      end
    end
  end
end
