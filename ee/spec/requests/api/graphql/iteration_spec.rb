# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying an Iteration', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group_member) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence ) }

  let(:current_user) { group_member }
  let(:fields) { 'title' }
  let(:query) do
    graphql_query_for('iteration', { id: iteration.to_global_id.to_s }, fields)
  end

  subject { graphql_data['iteration'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user has access to the iteration' do
    before_all do
      group.add_guest(group_member)
    end

    it_behaves_like 'a working graphql query'

    it { is_expected.to include('title' => iteration.name) }

    context 'when `report` field is included' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:subgroup) { create(:group, :private, parent: group) }
      let_it_be(:project1) { create(:project, group: group) }
      let_it_be(:project2) { create(:project, group: group) }
      let_it_be(:subgroup_project) { create(:project, group: subgroup) }
      let_it_be(:project1_member) { create(:user) }
      let_it_be(:project2_member) { create(:user) }
      let_it_be(:subgroup_member) { create(:user) }

      subject { graphql_data['iteration']['report'] }

      before_all do
        project1.add_guest(project1_member)
        project2.add_guest(project2_member)
        subgroup.add_guest(subgroup_member)

        issue1 = create(:issue, project: project1)
        issue2 = create(:issue, project: project1)
        issue3 = create(:issue, project: project2)
        subgroup_issue1 = create(:issue, project: subgroup_project)

        create(:resource_iteration_event, issue: issue1, iteration: iteration, action: :add, created_at: 2.days.ago)
        create(:resource_iteration_event, issue: issue2, iteration: iteration, action: :add, created_at: 2.days.ago)
        create(:resource_iteration_event, issue: issue3, iteration: iteration, action: :add, created_at: 2.days.ago)
        create(:resource_iteration_event, issue: subgroup_issue1, iteration: iteration, action: :add, created_at: 2.days.ago)

        # These are created to check the report only counts the iteration events for the "iteration".
        other_iteration = create(:iteration, iterations_cadence: cadence)
        subgroup_iteration = create(:iteration, iterations_cadence: cadence)
        issue4 = create(:issue, project: project2)
        subgroup_issue2 = create(:issue, project: subgroup_project)
        create(:resource_iteration_event, issue: issue4, iteration: other_iteration, action: :add, created_at: 2.days.ago)
        create(:resource_iteration_event, issue: subgroup_issue2, iteration: subgroup_iteration, action: :add, created_at: 2.days.ago)
      end

      context 'when fullPath argument is not provided' do
        let(:fields) { 'report { burnupTimeSeries { scopeCount } }' }

        where(:current_user, :expected_scope_count) do
          # Iteration is a group-level object. When a user can see it, the user should be able to
          # see the count of all the issues belonging to the group even if the user is not authorized for all projects.
          ref(:group_member)    | 4
          ref(:project1_member) | 4
        end

        with_them do
          it { is_expected.to include({ "burnupTimeSeries" => [{ "scopeCount" => expected_scope_count }] }) }
        end
      end

      context 'when fullPath argument is provided' do
        let(:fields) { "report(fullPath: \"#{scope.full_path}\") { burnupTimeSeries { scopeCount } }" }

        context 'when current user has authorized access to one or more projects under the namespace' do
          where(:scope, :current_user, :expected_scope_count) do
            ref(:group)    | ref(:group_member)    | 4
            ref(:group)    | ref(:project1_member) | 4
            ref(:project1) | ref(:group_member)    | 2
            ref(:project1) | ref(:project1_member) | 2
            ref(:project2) | ref(:project2_member) | 1
            ref(:project2) | ref(:group_member)    | 1
            ref(:subgroup) | ref(:group_member)    | 1
            ref(:subgroup) | ref(:subgroup_member) | 1
          end

          with_them do
            it { is_expected.to include({ "burnupTimeSeries" => [{ "scopeCount" => expected_scope_count }] }) }
          end
        end

        context 'when no group or project matches the provided fullPath' do
          let(:fields) { "report(fullPath: \"abc\") { burnupTimeSeries { scopeCount } }" }

          with_them do
            it 'raises an exception' do
              expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does not exist or you don't have permission to perform this action"))
            end
          end
        end

        context 'when current user cannot access the given namespace' do
          let_it_be(:other_group) { create(:group, :private) }

          where(:scope, :current_user) do
            ref(:other_group) | ref(:group_member)
            ref(:project1)    | ref(:subgroup_member)
            ref(:project1)    | ref(:project2_member)
            ref(:project2)    | ref(:project1_member)
            ref(:subgroup)    | ref(:project1_member)
          end

          with_them do
            it 'raises an exception' do
              expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does not exist or you don't have permission to perform this action"))
            end
          end
        end
      end
    end
  end

  context 'when the user does not have access to the iteration' do
    it_behaves_like 'a working graphql query'

    it { is_expected.to be_nil }
  end

  context 'when ID argument is missing' do
    let(:query) do
      graphql_query_for('iteration', {}, 'id')
    end

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'iteration' is missing required arguments: id"))
    end
  end

  describe 'scoped path' do
    let_it_be(:project) { create(:project, :private, group: group) }

    shared_examples 'scoped path' do
      let(:queried_iteration_id) { queried_iteration.to_global_id.to_s }
      let(:iteration_nodes) do
        nodes = <<~NODES
          nodes {
            scopedPath
            scopedUrl
            webPath
            webUrl
          }
        NODES

        query_graphql_field('iterations', { id: queried_iteration_id }, nodes)
      end

      before_all do
        group.add_guest(group_member)
      end

      specify do
        expect(subject).to include(
          'scopedPath' => expected_scope_path,
          'scopedUrl' => expected_scope_url,
          'webPath' => expected_web_path,
          'webUrl' => expected_web_url
        )
      end

      context 'when given a raw model id (backward compatibility)' do
        let(:queried_iteration_id) { queried_iteration.id }

        specify do
          expect(subject).to include(
            'scopedPath' => expected_scope_path,
            'scopedUrl' => expected_scope_url,
            'webPath' => expected_web_path,
            'webUrl' => expected_web_url
          )
        end
      end
    end

    context 'inside a project context' do
      subject { graphql_data['project']['iterations']['nodes'].first }

      let(:query) do
        graphql_query_for('project', { full_path: project.full_path }, iteration_nodes)
      end

      describe 'group-owned iteration' do
        it_behaves_like 'scoped path' do
          let(:queried_iteration) { iteration }
          let(:expected_scope_path) { group_iteration_path(project, iteration.id) }
          let(:expected_scope_url) { /#{expected_scope_path}$/ }
          let(:expected_web_path) { group_iteration_path(group, iteration.id) }
          let(:expected_web_url) { /#{expected_web_path}$/ }
        end
      end
    end

    context 'inside a group context' do
      subject { graphql_data['group']['iterations']['nodes'].first }

      let(:query) do
        graphql_query_for('group', { full_path: group.full_path }, iteration_nodes)
      end

      describe 'group-owned iteration' do
        it_behaves_like 'scoped path' do
          let(:queried_iteration) { iteration }
          let(:expected_scope_path) { group_iteration_path(group, iteration.id) }
          let(:expected_scope_url) { /#{expected_scope_path}$/ }
          let(:expected_web_path) { group_iteration_path(group, iteration.id) }
          let(:expected_web_url) { /#{expected_web_path}$/ }
        end
      end

      describe 'group-owned iteration' do
        let(:sub_group) { create(:group, :private, parent: group) }
        let(:query) do
          graphql_query_for('group', { full_path: sub_group.full_path }, iteration_nodes)
        end

        it_behaves_like 'scoped path' do
          let(:queried_iteration) { iteration }
          let(:expected_scope_path) { group_iteration_path(sub_group, iteration.id) }
          let(:expected_scope_url) { /#{expected_scope_path}$/ }
          let(:expected_web_path) { group_iteration_path(group, iteration.id) }
          let(:expected_web_url) { /#{expected_web_path}$/ }
        end
      end
    end

    context 'root context' do
      subject { graphql_data['iteration'] }

      let(:query) do
        graphql_query_for('iteration', { id: iteration.to_global_id.to_s }, [:scoped_path, :scoped_url, :web_path, :web_url])
      end

      describe 'group-owned iteration' do
        it_behaves_like 'scoped path' do
          let(:queried_iteration) { iteration }
          let(:expected_scope_path) { group_iteration_path(group, iteration.id) }
          let(:expected_scope_url) { /#{expected_scope_path}$/ }
          let(:expected_web_path) { group_iteration_path(group, iteration.id) }
          let(:expected_web_url) { /#{expected_web_path}$/ }
        end
      end

      describe 'project-owned iteration' do
        it_behaves_like 'scoped path' do
          let(:queried_iteration) { project_iteration }
          let(:expected_scope_path) { group_iteration_path(group, iteration.id) }
          let(:expected_scope_url) { /#{expected_scope_path}$/ }
          let(:expected_web_path) { group_iteration_path(group, iteration.id) }
          let(:expected_web_url) { /#{expected_web_path}$/ }
        end
      end
    end
  end
end
