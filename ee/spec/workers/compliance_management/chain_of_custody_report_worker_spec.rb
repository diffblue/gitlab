# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::ChainOfCustodyReportWorker, feature_category: :compliance_management do
  let(:worker) { described_class.new }
  let(:service) { instance_double(Groups::ComplianceReportCsvService, csv_data: 'data') }
  let(:csv_data) { 'foo,bar,baz' }
  let(:service_response) { ServiceResponse.success(payload: csv_data) }
  let(:job_args) do
    { user_id: user.id, group_id: group.id }
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  describe "#perform" do
    before do
      allow(Groups::ComplianceReportCsvService).to receive(:new)
                                                     .with(user, group, {})
                                                     .and_return(service)
      allow(service).to receive(:csv_data).and_return(service_response)
    end

    it 'has the `until_executed` deduplicate strategy' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    end

    context 'when the params are valid' do
      it 'calls the service' do
        worker.perform(job_args)

        expect(Groups::ComplianceReportCsvService).to have_received(:new)
        expect(service).to have_received(:csv_data)
      end

      it 'creates a notification' do
        expect(Notify).to receive(:merge_commits_csv_email)
                            .with(user, group, csv_data, a_string_including('csv'))
                            .and_return(double(deliver_now: true))

        worker.perform(job_args)
      end
    end

    context 'when an error is raised' do
      subject { worker.perform(job_args) }

      context 'when the csv fails to generate' do
        before do
          allow(service).to receive(:csv_data).and_return(
            ServiceResponse.error(message: 'boom')
          )
        end

        it 'raises an error' do
          expect { subject }.to raise_error('An error occurred generating the chain of custody report')
        end
      end

      context 'when no user id is passed' do
        let(:job_args) { super().merge(user_id: nil) }
        let(:error_message) { 'user_id and group_id are required arguments' }

        it 'logs the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
                                             .with(ActiveRecord::RecordNotFound)
          subject

          expect(Groups::ComplianceReportCsvService).not_to have_received(:new)
        end
      end

      context 'when no group id is passed' do
        let(:job_args) { super().merge(group_id: nil) }
        let(:error_message) { 'user_id and group_id are required arguments' }

        it 'logs the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(ActiveRecord::RecordNotFound)

          subject

          expect(Groups::ComplianceReportCsvService).not_to have_received(:new)
        end
      end
    end
  end
end
