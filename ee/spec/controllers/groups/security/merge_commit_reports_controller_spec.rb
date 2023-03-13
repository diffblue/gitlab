# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::MergeCommitReportsController, feature_category: :compliance_management do
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
        let(:export_csv_service) do
          instance_spy(Groups::ComplianceReportCsvService)
        end

        before_all do
          group.add_owner(user)
        end

        before do
          stub_licensed_features(group_level_compliance_dashboard: true)
          allow(Groups::ComplianceReportCsvService).to receive(:new).and_return(export_csv_service)
        end

        it "tells the service to enqueue a job" do
          subject

          expect(flash[:notice]).to eq 'An email will be sent with the report attached after it is generated.'
          expect(export_csv_service).to have_received(:enqueue_worker).once
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
