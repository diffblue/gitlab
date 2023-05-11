# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Ai::GenerateConfig, feature_category: :pipeline_composition do
  let(:mutation) { described_class.new(object: project, context: { current_user: current_user }, field: nil) }

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:user_content) { 'my content' }

  let(:params) do
    {
      project_path: project.full_path,
      user_content: user_content
    }
  end

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(**params) }

    context 'when user cannot read the project' do
      it 'raises an error if the resource is not accessible to the user' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user can read the project' do
      before do
        project.add_maintainer(current_user)
      end

      it 'returns no errors' do
        expect(resolve).to eq(
          user_message: nil,
          errors: []
        )
      end

      context 'when feature flag disabled' do
        before do
          stub_feature_flags(ai_ci_config_generator: false)
        end

        it 'returns an error' do
          expect(resolve).to eq(
            user_message: nil,
            errors: ['Feature not available']
          )
        end
      end
    end
  end
end
