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

    context 'when user is not a project member' do
      it 'raises an error if the resource is not accessible to the user' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is a project member who cannot create a pipeline' do
      before do
        project.add_reporter(current_user)
      end

      it 'raises an error if the resource is not accessible to the user' do
        expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is a project member who can create a pipeline' do
      before do
        project.add_developer(current_user)
      end

      it 'calls the service returning the user message payload' do
        message = instance_double(Ci::Editor::AiConversation::Message)
        service = instance_double(
          Ci::Llm::AsyncGenerateConfigService,
          execute: ServiceResponse.success(payload: message)
        )
        expect(Ci::Llm::AsyncGenerateConfigService).to receive(:new).and_return(service)
        expect(service).to receive(:execute)

        expect(resolve).to eq(
          user_message: message,
          errors: []
        )
      end
    end
  end
end
