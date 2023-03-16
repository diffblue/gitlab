# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::PublishWorker, feature_category: :incident_management do
  include ExclusiveLeaseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:worker) { described_class.new }
  let(:logger) { worker.send(:logger) }
  let(:service) { instance_double(StatusPage::PublishService) }
  let(:service_result) { ServiceResponse.success }

  before do
    allow(StatusPage::PublishService)
      .to receive(:new).with(user: user, project: project, issue_id: issue.id)
      .and_return(service)
    allow(service).to receive(:execute)
      .and_return(service_result)
  end

  describe '#perform' do
    subject { worker.perform(user.id, project.id, issue.id) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [user.id, project.id, issue.id] }

      context 'when service succeeds' do
        it 'execute the service' do
          expect(service).to receive(:execute)

          subject
        end
      end

      context 'with unknown project' do
        let(:project) { build(:project) }

        it 'does not execute the service' do
          expect(StatusPage::PublishService).not_to receive(:execute)

          subject
        end
      end

      context 'when service returns an error' do
        let(:error_message) { 'some message' }
        let(:service_result) { ServiceResponse.error(message: error_message) }

        it 'succeeds and logs the error' do
          expect(logger)
            .to receive(:info)
            .with(a_hash_including('message' => error_message))
            .exactly(worker_exec_times).times

          subject
        end
      end
    end

    context 'when service raises an exception' do
      let(:error_message) { 'some exception' }
      let(:exception) { StandardError.new(error_message) }

      it 're-raises exception' do
        allow(service).to receive(:execute).and_raise(exception)

        expect { subject }.to raise_error(exception)
      end
    end
  end
end
