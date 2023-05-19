# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CloseService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:current_user) { merge_request.author }
  let(:service) { described_class.new(project: project, current_user: current_user) }

  describe '#execute' do
    it 'executes the close service' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:execute)
          .with(merge_request)
      end

      service.execute(merge_request)
    end

    context 'when a temporary unapproval is needed for the MR' do
      it 'removes the unmergeable flag after the service is run' do
        merge_request.approval_state.temporarily_unapprove!

        service.execute(merge_request)

        merge_request.reload

        expect(merge_request.approval_state.temporarily_unapproved?).to be_falsey
      end

      context 'when the service fails' do
        before do
          allow_next_instance_of(described_class) do |close_service|
            allow(close_service).to receive(:execute).and_return(ServiceResponse.error(message: 'some error'))
          end
        end

        it 'does not remove the unmergeable flag' do
          merge_request.approval_state.temporarily_unapprove!

          service.execute(merge_request)

          merge_request.reload

          expect(merge_request.approval_state.temporarily_unapproved?).to be_truthy
        end
      end
    end
  end
end
