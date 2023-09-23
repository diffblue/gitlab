# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationConfigurationCreateBotWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let(:current_user_id) { user.id }

    subject(:run_worker) { described_class.new.perform(project_id, current_user_id) }

    before do
      project.add_owner(user)
    end

    context 'with invalid project_id' do
      let(:project_id) { non_existing_record_id }

      it 'exits without error' do
        expect(Security::Orchestration::CreateBotService).not_to receive(:new)

        expect { run_worker }.not_to raise_error
      end
    end

    context 'with valid project_id' do
      let(:project_id) { project.id }

      context 'when current user is not provided' do
        let(:project_id) { project.id }

        context 'when user with given current_user_id does not exist' do
          let(:current_user_id) { non_existing_record_id }

          it 'does not call the create bot service' do
            expect(Security::Orchestration::CreateBotService).not_to receive(:new)

            run_worker
          end

          it 'exits without error' do
            expect { run_worker }.not_to raise_error
          end
        end

        context 'when current_user_id is set to nil' do
          let(:current_user_id) { nil }

          it 'calls the create bot service and skips authorization' do
            expect_next_instance_of(
              Security::Orchestration::CreateBotService,
              project,
              nil,
              skip_authorization: true
            ) do |service|
              expect(service).to receive(:execute).and_call_original
            end

            run_worker
          end
        end
      end

      context 'when current user is provided' do
        let(:current_user_id) { user.id }

        let(:project_id) { project.id }

        it 'calls the create bot service' do
          expect_next_instance_of(
            Security::Orchestration::CreateBotService,
            project,
            user,
            skip_authorization: false
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
end
