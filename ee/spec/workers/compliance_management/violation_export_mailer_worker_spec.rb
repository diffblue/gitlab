# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::ViolationExportMailerWorker, feature_category: :compliance_management,
  type: :worker do
  describe '#perform', travel_to: '2023-09-22' do
    let_it_be(:user) { create :user }
    let_it_be(:namespace) { create :group, :private }

    before_all do
      namespace.add_owner user
    end

    subject(:worker) { described_class.new.perform user.id, namespace.id }

    context "with compliance_violation_csv_export ff implicitly enabled" do
      it 'schedules mail for delivery' do
        expect { worker }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "with compliance_violation_csv_export ff disabled" do
      it 'schedules mail for delivery' do
        stub_feature_flags compliance_violation_csv_export: false

        expect(ComplianceManagement::Violations::ExportService).not_to receive(:new)

        expect { worker }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with failing export' do
      let(:error_response) { ServiceResponse.error message: 'What air defense doing?' }

      before do
        allow_next_instance_of(ComplianceManagement::Violations::ExportService) do |export_service|
          allow(export_service).to receive(:execute).and_return(error_response)
        end
      end

      it 'schedules no mail for delivery and returns appropriate error' do
        expect { worker }.to raise_error(described_class::ExportFailedError)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context 'with unknown record' do
      let(:user) { instance_double 'User', id: non_existing_record_id }

      it 'rescues from not found error and logs exception' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(ActiveRecord::RecordNotFound)

        worker
      end
    end
  end
end
