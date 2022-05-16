# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::TrainingProviderUpdate do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:training, refind: true) { create(:security_training) }

    let(:arguments) { { project_path: project.full_path, provider_id: training.provider.to_global_id, is_enabled: true, is_primary: false } }
    let(:service_result) { { status: :success, training: training } }
    let(:service_object) { instance_double(::Security::UpdateTrainingService, execute: service_result) }

    subject(:mutation_result) { resolve(described_class, args: arguments, ctx: { current_user: user }) }

    before do
      stub_licensed_features(security_dashboard: true)

      allow(::Security::UpdateTrainingService).to receive(:new).and_return(service_object)
    end

    context 'when the user is not authorized' do
      it 'does not permit the action' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          mutation_result
        end
      end
    end

    context 'when the user is authorized' do
      before do
        project.add_developer(user)
      end

      context 'when the mutation fails' do
        let(:service_result) { { status: :error, message: 'Error', training: training } }

        it { is_expected.to include({ training: training.provider, errors: ['Error'] }) }
      end

      context 'when the mutation succeeds' do
        it { is_expected.to include({ training: training.provider, errors: [] }) }

        describe 'training' do
          subject { mutation_result[:training] }

          context 'when the training is deleted' do
            context 'when training is not primary' do
              before do
                training.destroy!
              end

              it { is_expected.to have_attributes(is_enabled: false, is_primary: false) }
            end

            context 'when training is primary' do
              before do
                training.update!(is_primary: true)
                training.destroy!
              end

              it { is_expected.to have_attributes(is_enabled: false, is_primary: false) }
            end
          end

          context 'when the training is not deleted' do
            it { is_expected.to have_attributes(is_enabled: true, is_primary: false) }
          end
        end
      end
    end
  end
end
