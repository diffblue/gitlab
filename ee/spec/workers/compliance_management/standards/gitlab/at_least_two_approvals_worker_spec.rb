# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Standards::Gitlab::AtLeastTwoApprovalsWorker,
  feature_category: :compliance_management do
  let_it_be(:worker) { described_class.new }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let(:job_args) do
    { 'project_id' => project_id, 'user_id' => user_id }
  end

  describe '#perform' do
    context 'for non existent project' do
      let(:project_id) { non_existing_record_id }
      let(:user_id) { user.id }

      it 'does not invoke AtLeastTwoApprovalsWorker' do
        expect(ComplianceManagement::Standards::Gitlab::AtLeastTwoApprovalsService).not_to receive(:new)

        worker.perform(job_args)
      end
    end

    context 'for non existent user' do
      let(:user_id) { non_existing_record_id }
      let(:project_id) { project.id }

      it 'invokes AtLeastTwoApprovalsService' do
        expect(ComplianceManagement::Standards::Gitlab::AtLeastTwoApprovalsService)
          .to receive(:new).and_call_original

        worker.perform(job_args)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { { 'project_id' => project.id, 'user_id' => user.id } }
    end
  end
end
