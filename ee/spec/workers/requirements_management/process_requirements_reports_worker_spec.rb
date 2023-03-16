# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::ProcessRequirementsReportsWorker, feature_category: :requirements_management do
  describe '#perform' do
    subject { described_class.new.perform(build_id) }

    context 'build exists' do
      let_it_be(:build) { create(:ci_build) }

      let(:build_id) { build.id }

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [build.id] }
      end

      it 'processes requirements reports' do
        service_double = instance_double(RequirementsManagement::ProcessTestReportsService, execute: true)
        expect(RequirementsManagement::ProcessTestReportsService).to receive(:new).and_return(service_double)

        subject
      end

      context 'when the service raises a Gitlab::Access::AccessDeniedError' do
        before do
          allow_next_instance_of(RequirementsManagement::ProcessTestReportsService) do |instance|
            allow(instance).to receive(:execute).and_raise(Gitlab::Access::AccessDeniedError)
          end
        end

        it 'rescues the error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'build does not exist' do
      let(:build_id) { non_existing_record_id }

      it 'does not store requirements reports' do
        expect(RequirementsManagement::ProcessTestReportsService).not_to receive(:new)

        subject
      end
    end
  end
end
