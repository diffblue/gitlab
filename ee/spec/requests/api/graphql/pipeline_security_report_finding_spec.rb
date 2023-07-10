# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PipelineSecurityReportFinding', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  context 'when loading a merge request' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:build) { create(:ee_ci_build, :sast, :success, pipeline: pipeline, project: project) }
    let_it_be(:vulnerability) { create(:vulnerability, :detected, project: project) }
    let_it_be(:scan) do
      create(:security_scan, :latest_successful, :with_findings, project: project, pipeline: pipeline, build: build)
    end

    let_it_be(:uuid) { scan.findings.first.uuid }
    let_it_be(:vulnerability_finding) do
      create(:vulnerabilities_finding, uuid: uuid, project: project, vulnerability: vulnerability, report_type: :sast)
    end

    let_it_be(:merge_request) do
      create(:merge_request, :unique_branches, source_project: project).tap do |merge_request|
        create(:vulnerabilities_merge_request_link, vulnerability: vulnerability, merge_request: merge_request)
      end
    end

    let(:query) do
      graphql_query_for(:project, { full_path: project.full_path },
        query_graphql_field(:pipeline, { iid: pipeline.iid.to_s },
          query_graphql_field(:security_report_finding, { uuid: uuid },
            query_graphql_field(:merge_request, [:id])
          )
        )
      )
    end

    context 'when the current user is authorized' do
      subject { post_graphql(query, current_user: current_user) }

      before do
        stub_licensed_features(sast: true, security_dashboard: true)
        project.add_maintainer(current_user)
      end

      it 'returns the merge request' do
        subject

        expect(
          graphql_data_at(:project, :pipeline, :security_report_finding, :merge_request)
        ).to match(a_graphql_entity_for(id: merge_request.to_global_id.to_s))
      end
    end
  end
end
