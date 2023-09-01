# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EnterpriseUsers::DisassociateWorker, feature_category: :user_management do
  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:user) { create(:user) }
    let(:job_args) { [user.id] }
  end

  describe '#perform' do
    let(:user) { create(:user) }

    context 'when user does not exist for given user_id' do
      it 'does not do anything' do
        expect(Groups::EnterpriseUsers::DisassociateService).not_to receive(:new)

        worker.perform(-1)
      end
    end

    it 'executes Groups::EnterpriseUsers::DisassociateService for the user' do
      expect_next_instance_of(Groups::EnterpriseUsers::DisassociateService, user: user) do |disassociate_service|
        expect(disassociate_service).to receive(:execute).and_call_original
      end

      worker.perform(user.id)
    end
  end
end
