# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SecurityTrainingUpdate', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:training, refind: true) { create(:security_training) }

  let(:mutation_name) { :security_training_update }
  let(:mutation) do
    graphql_mutation(
      mutation_name,
      parameters
    )
  end

  let(:parameters) do
    {
      project_path: project.full_path,
      provider_id: training.provider.to_global_id,
      is_enabled: is_enabled,
      is_primary: is_primary
    }
  end

  let(:is_enabled) { true }
  let(:is_primary) { false }

  shared_examples 'it creates a training on the project' do |expected_is_primary:|
    example do
      expect(project.security_trainings.count).to eq 0
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_mutation_response(mutation_name)['errors']).to be_empty

      security_training = project.reload.security_trainings.first
      expect(security_training.provider).to eq training.provider
      expect(security_training.is_primary).to eq expected_is_primary
    end
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user has permission' do
    before_all do
      project.add_developer(current_user)
    end

    context 'when is_enabled is true' do
      let(:is_enabled) { true }

      it_behaves_like 'it creates a training on the project', expected_is_primary: false

      context 'when is_primary is not provided' do
        let(:parameters) do
          {
            project_path: project.full_path,
            provider_id: training.provider.to_global_id,
            is_enabled: is_enabled
          }
        end

        it_behaves_like 'it creates a training on the project', expected_is_primary: false
      end

      context 'when is_primary is null' do
        let(:is_primary) { nil }

        it_behaves_like 'it creates a training on the project', expected_is_primary: false
      end

      context 'when is_primary is true' do
        let(:is_primary) { true }

        it_behaves_like 'it creates a training on the project', expected_is_primary: true
      end
    end

    context 'when is_enabled is false' do
      let(:is_enabled) { false }
      let!(:project_security_training) { create(:security_training, project: project, provider: training.provider) }

      it 'removes the training from the project' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { project.reload.security_trainings.count }.from(1).to(0)
      end
    end
  end
end
