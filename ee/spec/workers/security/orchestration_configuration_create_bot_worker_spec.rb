# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationConfigurationCreateBotWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    let(:project_id) { non_existing_record_id }

    subject(:run_worker) { described_class.new.perform(project_id, current_user) }

    before do
      project.add_owner(current_user)
    end

    it 'exits without error' do
      expect(Security::Orchestration::CreateBotService).not_to receive(:new)

      expect { run_worker }.not_to raise_error
    end

    context 'with valid project_id' do
      let(:project_id) { project.id }

      it 'calls the create bot service' do
        expect_next_instance_of(
          Security::Orchestration::CreateBotService,
          project,
          current_user
        ) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        run_worker
      end

      context 'when the CreateBotService raises an access denied error' do
        before do
          allow_next_instance_of(Security::Orchestration::CreateBotService) do |service|
            allow(service).to receive(:execute).and_raise(Gitlab::Access::AccessDeniedError)
          end
        end

        it 'exits without error' do
          expect { run_worker }.not_to raise_error
        end
      end
    end
  end
end
