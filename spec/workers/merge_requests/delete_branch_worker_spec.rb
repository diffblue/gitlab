# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::DeleteBranchWorker do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }

  let(:branch) { merge_request.source_branch }
  let(:sha) { merge_request.source_branch_sha }
  let(:retarget_branch) { true }
  let(:worker) { described_class.new }
  let(:service_result) { ServiceResponse.success(message: 'placeholder') }

  before do
    allow_next_instance_of(::Branches::DeleteService) do |instance|
      allow(instance).to receive(:execute).with(merge_request.source_branch).and_return(service_result)
    end
  end

  describe '#perform' do
    context 'when the branch does not exist' do
      let(:branch) { 'non_existent_branch_name' }

      it 'does nothing' do
        expect(::Branches::DeleteService).not_to receive(:new)

        worker.perform(non_existing_record_id, user.id, branch, retarget_branch)
      end
    end

    context 'with a non-existing merge request' do
      it 'does nothing' do
        expect(::Branches::DeleteService).not_to receive(:new)

        worker.perform(non_existing_record_id, user.id, branch, retarget_branch)
      end
    end

    context 'with a non-existing user' do
      it 'does nothing' do
        expect(::Branches::DeleteService).not_to receive(:new)

        worker.perform(merge_request.id, non_existing_record_id, branch, retarget_branch)
      end
    end

    context 'with existing user and merge request' do
      it 'calls service to delete source branch' do
        expect_next_instance_of(::Branches::DeleteService) do |instance|
          expect(instance).to receive(:execute).with(merge_request.source_branch).and_return(service_result)
        end

        worker.perform(merge_request.id, user.id, branch, retarget_branch)
      end

      context 'when retarget branch param is true' do
        it 'calls the retarget chain service' do
          expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
            expect(instance).to receive(:execute).with(merge_request)
          end

          worker.perform(merge_request.id, user.id, branch, retarget_branch)
        end
      end

      context 'when retarget branch param is false' do
        let(:retarget_branch) { false }

        it 'does not call the retarget chain service' do
          expect(::MergeRequests::RetargetChainService).not_to receive(:new)

          worker.perform(merge_request.id, user.id, branch, retarget_branch)
        end
      end

      context 'when delete service returns an error' do
        let(:service_result) { ServiceResponse.error(message: 'placeholder') }

        it 'tracks and raises the exception' do
          expect_next_instance_of(::Branches::DeleteService) do |instance|
            expect(instance).to receive(:execute).with(merge_request.source_branch).and_return(service_result)
          end

          expect(service_result).to receive(:track_and_raise_exception).and_call_original

          expect { worker.perform(merge_request.id, user.id, branch, retarget_branch) }.to raise_error(StandardError)
        end

        it 'still calls the retarget chain service' do
          expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
            expect(instance).to receive(:execute).with(merge_request)
          end

          expect { worker.perform(merge_request.id, user.id, branch, retarget_branch) }.to raise_error(StandardError)
        end

        context 'when track_and_raise_delete_source_errors is disabled' do
          before do
            stub_feature_flags(track_and_raise_delete_source_errors: false)
          end

          it 'does not track the exception' do
            expect_next_instance_of(::Branches::DeleteService) do |instance|
              expect(instance).to receive(:execute).with(merge_request.source_branch).and_return(service_result)
            end

            expect(service_result).not_to receive(:track_and_raise_exception)

            expect { worker.perform(merge_request.id, user.id, branch, retarget_branch) }.not_to raise_error
          end
        end
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:merge_request) { create(:merge_request) }
      let(:job_args) { [merge_request.id, sha, user.id, true] }
    end
  end
end
