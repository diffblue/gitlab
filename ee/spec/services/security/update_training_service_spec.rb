# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::UpdateTrainingService, feature_category: :security_policy_management do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:training_provider) { create(:security_training_provider) }

    let(:is_primary) { false }
    let(:is_enabled) { false }
    let(:provider_id) { training_provider.to_global_id }
    let(:params) { { provider_id: provider_id, is_enabled: is_enabled, is_primary: is_primary } }
    let(:service_object) { described_class.new(project, params) }

    subject(:update_training) { service_object.execute }

    context 'when there is no provider with the given id' do
      let(:provider_id) { 'gid://gitlab/Security::TrainingProvider/0' }

      it 'does not raise error' do
        expect { update_training }.not_to raise_error
      end
    end

    context 'when `is_enabled` argument is false' do
      context 'when the deletion fails' do
        before do
          allow_next_instance_of(Security::Training) do |training_instance|
            allow(training_instance).to receive(:destroy) { training_instance.errors.add(:base, 'Foo') }
          end
        end

        it { is_expected.to match({ status: :error, message: 'Updating security training failed!', training: an_instance_of(Security::Training) }) }
      end

      context 'when there is no training' do
        it { is_expected.to match({ status: :success, training: an_instance_of(Security::Training) }) }
      end

      context 'when there is a training' do
        let!(:training) { create(:security_training, project: project, provider: training_provider) }

        it { is_expected.to eq({ status: :success, training: training }) }

        it 'deletes the existing training' do
          expect { update_training }.to change { project.security_trainings.count }.by(-1)
        end
      end
    end

    context 'when `is_enabled` argument is true' do
      let(:is_enabled) { true }

      context 'when updating the training fails' do
        before do
          allow_next_instance_of(Security::Training) do |training_instance|
            allow(training_instance).to receive(:update) { training_instance.errors.add(:base, 'Foo') }
          end
        end

        it { is_expected.to match({ status: :error, message: 'Updating security training failed!', training: an_instance_of(Security::Training) }) }
      end

      context 'when `is_primary` argument is false' do
        context 'when there is no security training for the project with given provider' do
          it 'creates a new security training record for the project' do
            expect { update_training }.to change { project.security_trainings.where(is_primary: false).count }.by(1)
          end
        end

        context 'when there is a security training for the project with given provider' do
          let!(:existing_security_training) { create(:security_training, :primary, project: project, provider: training_provider) }

          it 'updates the `is_primary` attribute of the existing security training records to false' do
            expect { update_training }.to change { existing_security_training.reload.is_primary }.from(true).to(false)
          end
        end
      end

      context 'when `is_primary` argument is true' do
        let(:is_primary) { true }

        context 'when there is already a primary training for the project' do
          let_it_be(:other_training) { create(:security_training, :primary, project: project) }

          context 'when there is no security training for the project with given provider' do
            it 'creates a new security training record for the project' do
              expect { update_training }.to change { other_training.reload.is_primary }.to(false)
                                        .and change { project.security_trainings.count }.by(1)
                                        .and not_change { project.security_trainings.where(is_primary: true).count }
            end
          end

          context 'when there is a security training for the project with given provider' do
            let!(:existing_security_training) { create(:security_training, project: project, provider: training_provider) }

            it 'updates the `is_primary` attribute of the security training records' do
              expect { update_training }.to change { existing_security_training.reload.is_primary }.from(false).to(true)
                                        .and change { other_training.reload.is_primary }.from(true).to(false)
            end
          end
        end

        context 'when there is not a primary training for the project' do
          context 'when there is no security training for the project with given provider' do
            it 'creates a new security training record for the project' do
              expect { update_training }.to change { project.security_trainings.where(is_primary: true).count }.by(1)
            end
          end

          context 'when there is a security training for the project with given provider' do
            let!(:existing_security_training) { create(:security_training, project: project, provider: training_provider) }

            it 'updates the `is_primary` attribute of the existing security training record to true' do
              expect { update_training }.to change { existing_security_training.reload.is_primary }.from(false).to(true)
            end
          end
        end
      end

      context 'when `is_primary` parameter is omitted' do
        it 'defaults to false' do
          params.delete(:is_primary)
          expect { update_training }.to change { project.security_trainings.where(is_primary: false).count }.by(1)
        end
      end
    end
  end
end
