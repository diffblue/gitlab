# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting test reports of a requirement', feature_category: :requirements_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:requirement) { create(:work_item, :requirement, project: project) }
  let_it_be(:test_report_1) { create(:test_report, requirement_issue: requirement, created_at: 3.days.from_now) }
  let_it_be(:test_report_2) { create(:test_report, requirement_issue: requirement, created_at: 2.days.from_now) }

  let(:test_reports_data) { graphql_data['project']['requirements']['edges'][0]['node']['testReports']['edges'] }
  let(:fields) do
    <<~QUERY
    edges {
      node {
        testReports {
          edges {
            node {
              #{all_graphql_fields_for('test_reports'.classify)}
            }
          }
        }
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

  before do
    stub_licensed_features(requirements: true)
  end

  context 'when user can read requirement' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns test reports successfully' do
      post_graphql(query, current_user: current_user)

      test_reports_ids = test_reports_data.map { |result| result['node']['id'] }
      all_records = [test_report_1.to_global_id.to_s, test_report_2.to_global_id.to_s]
      expect(test_reports_ids).to match_array(all_records)
    end

    context 'with pagination' do
      let_it_be(:data_path) { [:project, :requirement, :testReports] }
      let_it_be(:test_report_3) { create(:test_report, requirement_issue: requirement, created_at: 4.days.ago) }

      def pagination_query(params)
        graphql_query_for(:project, { full_path: project.full_path },
          "requirement { testReports(#{params}) { #{page_info} nodes { id } } }"
        )
      end

      let(:in_creation_order) do
        [test_report_3, test_report_2, test_report_1]
      end

      it_behaves_like 'sorted paginated query' do
        let(:sort_param)       { :CREATED_ASC }
        let(:first_param)      { 2 }
        let(:all_records) do
          in_creation_order.map { |r| global_id_of(r).to_s }
        end
      end

      it_behaves_like 'sorted paginated query' do
        let(:sort_param)       { :CREATED_DESC }
        let(:first_param)      { 2 }
        let(:all_records) do
          in_creation_order.reverse.map { |r| global_id_of(r).to_s }
        end
      end
    end
  end

  context 'when the user does not have access to the requirement' do
    it 'returns nil' do
      post_graphql(query)

      expect(graphql_data['project']).to be_nil
    end
  end
end
