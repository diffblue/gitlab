# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a requirement list for a project', feature_category: :requirements_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:requirement) do
    create(
      :work_item,
      :requirement,
      project: project,
      title: "Title: #{current_user.to_reference}",
      description: '## Description'
    ).requirement
  end

  let(:requirements_data) { graphql_data['project']['requirements']['edges'] }
  let(:fields) do
    <<~QUERY
      edges {
        node {
          #{all_graphql_fields_for('requirements'.classify, max_depth: 1)}
        }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('requirements', {}, fields)
    )
  end

  context 'when user has access to the project' do
    before do
      stub_licensed_features(requirements: true)
      project.add_developer(current_user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns requirements successfully' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_nil
      expect(requirements_data[0]['node']['id']).to eq requirement.to_global_id.to_s
    end

    it 'returns cached rendered html fields from requirement issue' do
      post_graphql(query, current_user: current_user)

      title_html = requirements_data[0]['node']['titleHtml']
      description_html = requirements_data[0]['node']['descriptionHtml']
      expect(title_html).to include('Title: <a href="/')
      expect(description_html).to include('<h2 ')
    end

    context 'when querying delegated fields' do
      let(:fields) do
        <<~QUERY
          edges {
            node {
              title
              description
              state
              titleHtml
              descriptionHtml
              createdAt
              updatedAt
              workItemIid
              author {
                name
              }
            }
          }
        QUERY
      end

      it 'does not execute n+1 queries' do
        post_graphql(query, current_user: current_user) # warm up
        control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

        create(:work_item, :requirement, project: project, author: create(:user))

        expect { post_graphql(query, current_user: current_user) }
          .not_to exceed_query_limit(control)
      end
    end

    context 'when limiting the number of results' do
      let(:query) do
        graphql_query_for(
          'project',
          { 'fullPath' => project.full_path },
          "requirements(first: 1) { #{fields} }"
        )
      end

      it_behaves_like 'a working graphql query' do
        before do
          post_graphql(query, current_user: current_user)
        end
      end
    end

    context 'query performance with test reports' do
      let_it_be(:test_report) { create(:test_report, requirement_issue: requirement.requirement_issue, state: "passed") }

      let(:fields) do
        <<~QUERY
          edges {
            node {
              lastTestReportState
              lastTestReportManuallyCreated
            }
          }
        QUERY
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

        create_list(:work_item, 3, :requirement, project: project) do |requirement|
          create(:test_report, requirement_issue: requirement, state: "passed")
        end

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
      end
    end

    describe 'filtering' do
      let_it_be(:filter_project) { create(:project, :public) }
      let_it_be(:other_project) { create(:project, :public) }
      let_it_be(:other_user) { create(:user, username: 'number8wire') }
      let_it_be(:requirement1) { create(:work_item, :requirement, iid: 27, project: filter_project, author: current_user, title: 'solve the halting problem') }
      let_it_be(:requirement2) { create(:work_item, :requirement, iid: 75, project: filter_project, author: other_user, title: 'something about kubernetes') }

      before do
        create(:test_report, requirement_issue: requirement1, state: :failed)
        create(:test_report, requirement_issue: requirement1, state: :passed)
        create(:test_report, requirement_issue: requirement2, state: :failed)

        post_graphql(query, current_user: current_user)
      end

      let(:requirements_data) { graphql_data['project']['requirements']['nodes'] }
      let(:params) { "" }

      let(:query) do
        graphql_query_for(
          'project',
          { 'fullPath' => filter_project.full_path },
          <<~REQUIREMENTS
            requirements#{params} {
              nodes {
                id
              }
            }
          REQUIREMENTS
        )
      end

      it_behaves_like 'a working graphql query'

      def match_single_result(requirement)
        expect(requirements_data[0]['id']).to eq requirement.to_global_id.to_s
      end

      context 'when given single author param' do
        let(:params) { '(authorUsername: "number8wire")' }

        it 'returns filtered requirements' do
          expect(graphql_errors).to be_nil
          match_single_result(requirement2.requirement)
        end
      end

      context 'when given multiple author param' do
        let(:params) { '(authorUsername: ["number8wire", "someotheruser"])' }

        it 'returns filtered requirements' do
          expect(graphql_errors).to be_nil
          match_single_result(requirement2.requirement)
        end
      end

      context 'when given search param' do
        let(:params) { '(search: "halting")' }

        it 'returns filtered requirements' do
          expect(graphql_errors).to be_nil
          match_single_result(requirement1.requirement)
        end
      end

      context 'when given author and search params' do
        let(:params) { '(search: "kubernetes", authorUsername: "number8wire")' }

        it 'returns filtered requirements' do
          expect(graphql_errors).to be_nil
          match_single_result(requirement2.requirement)
        end
      end

      context 'when given lastTestReportState' do
        let(:params) { '(lastTestReportState: PASSED)' }

        it 'returns filtered requirements' do
          expect(graphql_errors).to be_nil

          match_single_result(requirement1.requirement)
        end

        context 'for MISSING status' do
          let_it_be(:requirement3) { create(:work_item, :requirement, project: filter_project, author: other_user, title: 'need test report') }

          let(:params) { '(lastTestReportState: MISSING)' }

          it 'returns filtered requirements' do
            expect(graphql_errors).to be_nil

            match_single_result(requirement3.requirement)
          end
        end
      end
    end

    describe 'sorting and pagination' do
      let_it_be(:data_path) { [:project, :requirements] }

      def pagination_query(params)
        nested_internal_id_query(:project, sort_project, :requirements, params)
      end

      def pagination_results_data(data)
        data.map { |issue| issue.dig('iid').to_i }
      end

      context 'when sorting by created_at' do
        let_it_be(:sort_project) { create(:project, :public) }
        let_it_be(:requirement1) { create(:work_item, :requirement, project: sort_project, created_at: 3.days.from_now).requirement }
        let_it_be(:requirement2) { create(:work_item, :requirement, project: sort_project, created_at: 4.days.from_now).requirement }
        let_it_be(:requirement3) { create(:work_item, :requirement, project: sort_project, created_at: 2.days.ago).requirement }
        let_it_be(:requirement4) { create(:work_item, :requirement, project: sort_project, created_at: 5.days.ago).requirement }
        let_it_be(:requirement5) { create(:work_item, :requirement, project: sort_project, created_at: 1.day.ago).requirement }

        context 'when ascending' do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { :CREATED_ASC }
            let(:first_param) { 2 }
            let(:all_records) { [requirement4.iid, requirement3.iid, requirement5.iid, requirement1.iid, requirement2.iid] }
          end
        end

        context 'when descending' do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { :CREATED_DESC }
            let(:first_param) { 2 }
            let(:all_records) { [requirement2.iid, requirement1.iid, requirement5.iid, requirement3.iid, requirement4.iid] }
          end
        end
      end
    end
  end

  context 'when the user does not have access to the requirement' do
    before do
      stub_licensed_features(requirements: true)
    end

    it 'returns nil' do
      post_graphql(query)

      expect(graphql_data['project']).to be_nil
    end
  end

  context 'when requirements feature is not available' do
    before do
      stub_licensed_features(requirements: false)
      project.add_developer(current_user)
    end

    it 'returns nil' do
      post_graphql(query)

      expect(graphql_data['project']).to be_nil
    end
  end
end
