# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequest.findingReportsComparer', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:mock_report) do
    {
      status: :parsed,
      status_reason: 'An example reason',
      data: {
        base_report_out_of_date: false,
        base_report_created_at: nil,
        head_report_created_at: Time.now.to_s,
        added: [
          {
            uuid: SecureRandom.uuid,
            name: 'Test Vulnerability',
            description: 'Test description',
            severity: 'critical',
            state: 'confirmed',
            found_by_pipeline: {
              iid: 1
            }
          }
        ],
        fixed: []
      }.deep_stringify_keys
    }
  end

  let(:finding_reports_comparer_fields) do
    <<~QUERY
      findingReportsComparer(reportType: SAST) {
        status
        statusReason
        report {
          baseReportCreatedAt
          headReportCreatedAt
          baseReportOutOfDate
          added {
            uuid
            title
            description
            severity
            state
            foundByPipelineIid
          }
          fixed {
            uuid
            title
            description
            severity
            state
            foundByPipelineIid
          }
        }
      }
    QUERY
  end

  let(:merge_request_fields) do
    query_graphql_field(
      :merge_request,
      { iid: merge_request.iid.to_s },
      finding_reports_comparer_fields)
  end

  let(:query) { graphql_query_for(:project, { full_path: project.full_path }, merge_request_fields) }

  subject(:result) { graphql_data_at(:project, :merge_request, :finding_reports_comparer) }

  before do
    allow(::Security::MergeRequestSecurityReportGenerationService).to receive(:execute).and_return(mock_report)
  end

  context 'when the user is not authorized to read the field' do
    before do
      post_graphql(query, current_user: user)
    end

    it { is_expected.to be_nil }
  end

  context 'when the user is authorized to read the field' do
    before do
      stub_licensed_features(security_dashboard: true)

      project.add_developer(user)

      post_graphql(query, current_user: user)
    end

    it 'returns expected data' do
      expect(result).to match(a_hash_including(
        {
          status: 'PARSED',
          statusReason: 'An example reason',
          report: {
            baseReportOutOfDate: false,
            baseReportCreatedAt: nil,
            headReportCreatedAt: an_instance_of(String),
            added: [
              {
                uuid: an_instance_of(String),
                title: 'Test Vulnerability',
                description: 'Test description',
                severity: 'CRITICAL',
                state: 'CONFIRMED',
                foundByPipelineIid: '1'
              }
            ],
            fixed: []
          }
        }.deep_stringify_keys))
    end
  end
end
