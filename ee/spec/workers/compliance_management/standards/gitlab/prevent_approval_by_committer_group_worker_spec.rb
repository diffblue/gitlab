# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterGroupWorker,
  feature_category: :compliance_management do
  let_it_be(:worker) { described_class.new }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let(:job_args) do
    { 'group_id' => group_id, 'user_id' => user_id }
  end

  describe '#perform' do
    context 'for non existent group' do
      let(:group_id) { non_existing_record_id }
      let(:user_id) { user.id }

      it 'does not enqueue PreventApprovalByCommitterWorker' do
        expect(ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterWorker).not_to receive(:new)

        worker.perform(job_args)
      end
    end

    context 'for non existent user' do
      let(:user_id) { non_existing_record_id }
      let(:group_id) { group.id }

      it 'enqueues PreventApprovalByCommitterWorker' do
        allow(::ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterWorker)
          .to receive(:bulk_perform_async)
                .with([[{ 'project_id' => project.id, 'user_id' => nil }]]).and_call_original

        worker.perform(job_args)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { { 'group_id' => group.id, 'user_id' => user.id } }
    end
  end
end
