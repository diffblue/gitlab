# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::MergeCommitReportsController do
  let_it_be(:user) { create(:user, name: 'John Cena') }
  let_it_be(:group) { create(:group, name: 'Kombucha lovers') }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    subject { get :index, params: { group_id: group.to_param }, format: :csv }

    shared_examples 'returns not found' do
      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when feature is enabled' do
      context 'when user has access to dashboard' do
        let(:csv_data) do
          <<~CSV
            Merge Commit,Author,Merge Request,Merged By,Pipeline,Group,Project,Approver(s)
            12bsr67h,John Cena,10034,Brock Lesnar,2301,Kombucha lovers,Starter kit,Brock Lesnar | Kane
          CSV
        end

        let(:export_csv_service) do
          instance_spy(MergeCommits::ExportCsvService, csv_data: ServiceResponse.success(payload: csv_data))
        end

        before_all do
          group.add_owner(user)
        end

        before do
          stub_licensed_features(group_level_compliance_dashboard: true)
          stub_feature_flags(async_chain_of_custody_report: false)
          allow(MergeCommits::ExportCsvService).to receive(:new).and_return(export_csv_service)
        end

        it 'returns a csv file in response' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8')
        end

        context 'when async report feature flag is enabled' do
          before do
            stub_feature_flags(async_chain_of_custody_report: true)
          end

          it do
            subject

            expect(flash[:notice]).to eq 'An email will be sent with the report attached after it is generated.'
          end
        end

        context 'data validation' do
          it do
            subject

            expect(csv_response).to eq([
                                         [
                                           'Merge Commit',
                                           'Author',
                                           'Merge Request',
                                           'Merged By',
                                           'Pipeline',
                                           'Group',
                                           'Project',
                                           'Approver(s)'
                                         ],
                                         [
                                           '12bsr67h',
                                           'John Cena',
                                           '10034',
                                           'Brock Lesnar',
                                           '2301',
                                           'Kombucha lovers',
                                           'Starter kit',
                                           'Brock Lesnar | Kane'
                                         ]
                                       ])
          end
        end

        context 'when invalid' do
          let(:export_csv_service) do
            instance_spy(MergeCommits::ExportCsvService, csv_data: nil)
          end

          it do
            subject

            expect(flash[:alert]).to eq 'An error occurred while trying to generate the report. Please try again later.'
          end
        end
      end

      context 'when user does not have access to dashboard' do
        it_behaves_like 'returns not found'
      end
    end

    context 'when feature is not enabled' do
      it_behaves_like 'returns not found'
    end

    def csv_response
      CSV.parse(response.body)
    end
  end
end
