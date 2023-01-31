# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipeline(iid).codeQualityReportSummary',
feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            codeQualityReportSummary {
              count
              blocker
              critical
              major
              minor
              info
              unknown
            }
          }
        }
      }
    )
  end

  let(:code_quality_report_summary) { graphql_data_at(:project, :pipeline, :codeQualityReportSummary) }

  context 'when pipeline has a code quality report' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success, :with_codequality_reports, project: project) }

    context 'when user is member of the project' do
      before do
        project.add_developer(current_user)
      end

      it 'returns code quality report summary' do
        post_graphql(query, current_user: current_user)

        expect(code_quality_report_summary).to eq({
          "count" => 3, "blocker" => 0, "critical" => 0, "major" => 2, "minor" => 1, "info" => 0, "unknown" => 0
        })
      end
    end

    context 'when user is not a member of the project' do
      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(code_quality_report_summary).to be_nil
      end
    end
  end

  context 'when pipeline does not have a code quality report' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

    before do
      project.add_developer(current_user)
    end

    it 'returns an empty result' do
      post_graphql(query, current_user: current_user)

      expect(code_quality_report_summary).to be_nil
    end
  end
end
