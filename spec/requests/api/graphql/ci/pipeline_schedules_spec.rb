# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.pipelineSchedules' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

  let(:pipeline_schedule_graphql_data) { graphql_data_at(:project, :pipeline_schedules, :nodes, 0) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        refForDisplay
        refPath
        forTag
      }
    QUERY
  end

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipelineSchedules {
            #{fields}
          }
        }
      }
    )
  end

  before do
    pipeline_schedule.pipelines << build(:ci_pipeline, project: project)

    post_graphql(query, current_user: user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns calculated fields for a pipeline schedule' do
    ref_for_display = pipeline_schedule_graphql_data['refForDisplay']

    expect(ref_for_display).to eq('master')
    expect(pipeline_schedule_graphql_data['refPath']).to eq("/#{project.full_path}/-/commits/#{ref_for_display}")
    expect(pipeline_schedule_graphql_data['forTag']).to be(false)
  end
end
