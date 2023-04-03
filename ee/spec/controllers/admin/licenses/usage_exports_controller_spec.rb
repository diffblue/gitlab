# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Licenses::UsageExportsController, feature_category: :consumables_cost_management do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET show' do
    subject(:export_license_usage_file) { get :show, format: :csv }

    shared_examples 'does not update the license usage data exported flag' do
      it 'does not update the license usage data exported flag' do
        expect(Gitlab::CurrentSettings).not_to receive(:update)

        export_license_usage_file
      end
    end

    context 'with no current license' do
      before do
        allow(License).to receive(:current).and_return(nil)
        allow(HistoricalUserData::CsvService).to receive(:new).and_call_original
      end

      it 'redirects the user' do
        export_license_usage_file

        expect(response).to have_gitlab_http_status(:redirect)
      end

      include_examples 'does not update the license usage data exported flag'

      it 'does not attempt to create the CSV' do
        export_license_usage_file

        expect(HistoricalUserData::CsvService).not_to have_received(:new)
      end
    end

    context 'with a current license' do
      let(:license) { build(:license) }
      let(:csv_data) do
        <<~CSV
          Date,Billable User Count
          2020-08-26,1
          2020-08-27,2
        CSV
      end

      let(:csv_service) { instance_double(HistoricalUserData::CsvService, generate: csv_data) }
      let(:historical_data_relation) { :historical_data_relation }

      before do
        allow(License).to receive(:current).and_return(license)
        allow(license).to receive(:historical_data).and_return(historical_data_relation)
        allow(HistoricalUserData::CsvService).to receive(:new).with(historical_data_relation).and_return(csv_service)
      end

      context 'when current license is an offline cloud license' do
        let(:license) { build(:license, data: build(:gitlab_license, :cloud, :offline_enabled).export) }

        it 'updates the license usage data exported flag' do
          expect(Gitlab::CurrentSettings).to receive(:update).with(license_usage_data_exported: true).and_call_original

          export_license_usage_file
        end
      end

      context 'when current license is an online cloud license' do
        let(:license) { build(:license, data: build(:gitlab_license, :cloud).export) }

        include_examples 'does not update the license usage data exported flag'
      end

      context 'when current license is a legacy license' do
        include_examples 'does not update the license usage data exported flag'
      end

      context 'when data export fails' do
        before do
          allow_next_instance_of(HistoricalUserData::CsvService) do |service|
            allow(service).to receive(:generate).and_raise('error')
          end
        end

        it 'does not update the license usage data exported flag' do
          expect(Gitlab::CurrentSettings).not_to receive(:update)

          expect { export_license_usage_file }.to raise_error('error')
        end
      end

      it 'returns a csv file in response' do
        export_license_usage_file

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8')
      end

      it 'returns the expected response body' do
        export_license_usage_file

        expect(CSV.parse(response.body)).to eq([
                                                 ['Date', 'Billable User Count'],
                                                 %w[2020-08-26 1],
                                                 %w[2020-08-27 2]
                                               ])
      end
    end
  end
end
