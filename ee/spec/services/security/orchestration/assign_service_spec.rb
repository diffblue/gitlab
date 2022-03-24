# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Orchestration::AssignService do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:another_project) { create(:project) }

  let_it_be(:namespace, reload: true) { create(:group) }
  let_it_be(:another_namespace) { create(:group) }

  let_it_be(:policy_project) { create(:project) }
  let_it_be(:new_policy_project) { create(:project) }

  let(:container) { project }
  let(:another_container) { another_project }

  describe '#execute' do
    subject(:service) do
      described_class.new(container: container, current_user: nil, params: { policy_project_id: policy_project.id }).execute
    end

    before do
      service
    end

    shared_examples 'assigns policy project' do
      it 'assigns policy project to container' do
        expect(service).to be_success
        expect(
          container.security_orchestration_policy_configuration.security_policy_management_project_id
        ).to eq(policy_project.id)
      end

      it 'updates container with new policy project' do
        repeated_service =
          described_class.new(container: container, current_user: nil, params: { policy_project_id: new_policy_project.id }).execute

        expect(repeated_service).to be_success
        expect(
          container.security_orchestration_policy_configuration.security_policy_management_project_id
        ).to eq(new_policy_project.id)
      end

      it 'assigns same policy to different container' do
        repeated_service =
          described_class.new(container: another_container, current_user: nil, params: { policy_project_id: policy_project.id }).execute
        expect(repeated_service).to be_success
      end

      it 'unassigns project' do
        expect { described_class.new(container: container, current_user: nil, params: { policy_project_id: nil }).execute }.to change {
          container.reload.security_orchestration_policy_configuration
        }.to(nil)
      end

      it 'returns error when db has problem' do
        dbl_error = double('ActiveRecord')
        dbl =
          double(
            'Security::OrchestrationPolicyConfiguration',
            security_orchestration_policy_configuration: dbl_error
          )

        allow(dbl_error).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:has_existing_policy?).and_return(true)
          allow(instance).to receive(:container).and_return(dbl)
        end

        repeated_service =
          described_class.new(container: container, current_user: nil, params: { policy_project_id: new_policy_project.id }).execute

        expect(repeated_service).to be_error
      end

      describe 'with invalid project id' do
        subject(:service) { described_class.new(container: container, current_user: nil, params: { policy_project_id: 345 }).execute }

        it 'does not change policy project' do
          expect(service).to be_error

          expect { service }.not_to change { container.security_orchestration_policy_configuration }
        end
      end
    end

    context 'for project' do
      let(:container) { project }
      let(:another_container) { another_project }

      it_behaves_like 'assigns policy project'
    end

    context 'for namespace' do
      let(:container) { namespace }
      let(:another_container) { another_namespace }

      it_behaves_like 'assigns policy project'
    end
  end
end
