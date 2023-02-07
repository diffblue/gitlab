# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipeline(iid).codeQualityReports', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            codeQualityReports {
              nodes {
                #{all_graphql_fields_for('CodeQualityDegradation')}
              }
            }
          }
        }
      }
    )
  end

  let(:codequality_degradations) { graphql_data_at(:project, :pipeline, :codeQualityReports, :nodes) }

  context 'when pipeline has a code quality report' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success, :with_codequality_reports, project: project) }

    context 'when user is member of the project' do
      before do
        project.add_developer(current_user)
      end

      it 'returns all the code quality degradations' do
        post_graphql(query, current_user: current_user)

        expect(codequality_degradations.size).to eq(3)
      end

      it 'returns all the queried fields', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        codequality_degradations.each do |degradation|
          expect(degradation['description']).not_to be_nil
          expect(degradation['fingerprint']).not_to be_nil
          expect(degradation['severity']).not_to be_nil
          expect(degradation['path']).not_to be_nil
          expect(degradation['line']).not_to be_nil
          expect(degradation['webUrl']).not_to be_nil
          expect(degradation['engineName']).not_to be_nil
        end
      end

      it 'returns all the queried fields ordered by severity', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        codequality_severities = codequality_degradations.map { |degradation| degradation['severity'] }

        expect(codequality_severities).to eq(%w[MAJOR MAJOR MINOR])
      end
    end

    context 'when user is not a member of the project' do
      it 'returns no code quality degradations' do
        post_graphql(query, current_user: current_user)

        expect(codequality_degradations).to be_nil
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

      expect(codequality_degradations).to be_nil
    end
  end
end
