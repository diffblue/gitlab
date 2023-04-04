# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { merge_request.author }

  before do
    login_as(user)
  end

  describe 'GET #edit' do
    def get_edit
      get edit_project_merge_request_path(project, merge_request)
    end

    context 'when the project requires code owner approval' do
      before do
        stub_licensed_features(code_owners: true, code_owner_approval_required: true)

        get_edit # Warm the cache
      end

      it 'does not cause an extra queries when code owner rules are present' do
        control = ActiveRecord::QueryRecorder.new { get_edit }

        create(:code_owner_rule, merge_request: merge_request)

        # Threshold of 3 because we load the source_rule, users & group users for all rules
        expect { get_edit }.not_to exceed_query_limit(control).with_threshold(3)
      end

      it 'does not cause extra queries when multiple code owner rules are present' do
        create(:code_owner_rule, merge_request: merge_request)

        control = ActiveRecord::QueryRecorder.new { get_edit }

        create(:code_owner_rule, merge_request: merge_request)

        expect { get_edit }.not_to exceed_query_limit(control)
      end
    end
  end

  describe 'GET #index' do
    def get_index
      get project_merge_requests_path(project, state: 'opened')
    end

    it 'avoids N+1' do
      other_user = create(:user)
      create(:merge_request, :unique_branches, target_project: project, source_project: project)
      create_list(:approval_project_rule, 5, project: project, users: [user, other_user], approvals_required: 2)
      create_list(:approval_merge_request_rule, 5, merge_request: merge_request, users: [user, other_user], approvals_required: 2)

      control_count = ActiveRecord::QueryRecorder.new { get_index }.count

      create_list(:approval, 10)
      create(:approval_project_rule, project: project, users: [user, other_user], approvals_required: 2)
      create_list(:merge_request, 20, :unique_branches, target_project: project, source_project: project).each do |mr|
        create(:approval_merge_request_rule, merge_request: mr, users: [user, other_user], approvals_required: 2)
      end

      expect { get_index }.not_to exceed_query_limit(control_count)
    end
  end

  describe 'security_reports' do
    let_it_be(:merge_request) { create(:merge_request, :with_head_pipeline) }
    let_it_be(:user) { create(:user) }

    subject(:request_report) { get security_reports_project_merge_request_path(project, merge_request, type: :sast, format: :json) }

    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'when the user can not read project security resources' do
      before do
        project.add_guest(user)
      end

      it 'responds with 404' do
        request_report

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user can read project security resources' do
      before do
        project.add_developer(user)
      end

      context 'when the pipeline is pending' do
        it 'returns 204 HTTP status along with the `Poll-Interval` header' do
          request_report

          expect(response).to have_gitlab_http_status(:no_content)
          expect(response.headers['Poll-Interval']).to eq('3000')
        end
      end

      context 'when the pipeline is not pending' do
        before do
          merge_request.head_pipeline.reload.succeed!
        end

        context 'when the given type is invalid' do
          let(:error) { ::Security::MergeRequestSecurityReportGenerationService::InvalidReportTypeError }

          before do
            allow(::Security::MergeRequestSecurityReportGenerationService).to receive(:execute).and_raise(error)
          end

          it 'responds with 400' do
            request_report

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.header).not_to include('Poll-Interval')
          end
        end

        context 'when the given type is valid' do
          before do
            allow(::Security::MergeRequestSecurityReportGenerationService)
              .to receive(:execute).with(an_instance_of(MergeRequest), 'sast').and_return(report_payload)
          end

          context 'when comparison is being processed' do
            let(:report_payload) { { status: :parsing } }

            it 'returns 204 HTTP status along with the `Poll-Interval` header' do
              request_report

              expect(response).to have_gitlab_http_status(:no_content)
              expect(response.headers['Poll-Interval']).to eq('3000')
            end
          end

          context 'when comparison is done' do
            context 'when the comparison is errored' do
              let(:report_payload) { { status: :error } }

              it 'responds with 400' do
                request_report

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(response.header).not_to include('Poll-Interval')
              end
            end

            context 'when the comparision is succeeded' do
              let(:report_payload) { { status: :parsed, data: { added: ['foo'], fixed: ['bar'] } } }

              it 'responds with 200 along with the report payload' do
                request_report

                expect(response).to have_gitlab_http_status(:ok)
                expect(json_response).to eq({ 'added' => ['foo'], 'fixed' => ['bar'] })
              end
            end
          end
        end
      end
    end
  end
end
